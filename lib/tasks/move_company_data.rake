#
# Sample usage:
#   RAILS_ENV=test bin/rake recognize:move_company_data source_company_id=123 destination_company_id=234
#
# CLI Arguments (parsed from ENV):
#   source_company_id (required)
#   destination_company_id (required)
#   adjust_point_activities (optional) (true | false): defaults to 'false'
#   refresh_caches (optional) (true | false): defaults to 'true'
#   global_prefix (optional): defaults to "[#{source_company.name}]". Pass empty string to disable prefixing.
#   global_prefix_delimiter (optional): defaults to " "
#
# Confirmations:
#   - Asks confirmation before moving data, showing source/company domains.
#   - Also asks 2nd confirmation if violations of any known uniqueness constraints are found (listing the conflicting records).
#
# Ignored tables (having company_id column):
#   Company.has_one associations:
#     SamlConfiguration, Subscription, CompanyCustomization, CompanySettings
#   Other (without explicit associations):
#     ExternalActivities, CustomFieldMapping, CompanyDomain, JobStatus
#
namespace :recognize do
  desc 'Move (almost) all data from one company to another'
  task move_company_data: [:environment, :confirm_company_data_migration, :check_uniqueness_constraints] do
    source_company, destination_company = get_source_and_destination_company_from_env!
    global_prefix = get_global_prefix(source_company)
    global_prefix_delimiter = get_global_prefix_delimiter
    adjust_point_activities = adjust_point_activities?
    new_attrs = attrs_that_affect_uniqueness_constraints(source_company)
    prefixes = get_prefixes(source_company)

    migrator = CompanyDataMigrator.new(source_company: source_company, destination_company: destination_company,
                                       adjust_point_activities: adjust_point_activities,
                                       global_prefix: global_prefix, global_prefix_delimiter: global_prefix_delimiter,
                                       prefixes: prefixes, new_attrs: new_attrs)

    puts "#{separator_line}\n\n"
    puts 'Migrating Data:'
    migrator.migrate!

    puts 'Refreshing Caches:'
    migrator.refresh_caches if refresh_caches?

    puts "\nDone!\n#{separator_line}"
  end

  task confirm_company_data_migration: :environment do
    source_company, destination_company = get_source_and_destination_company_from_env!
    puts separator_line
    puts
    puts "You are about to migrate all Company Data from '#{source_company.domain}' to '#{destination_company.domain}'. (irreversible operation)"
    puts "Parameter infos:"
    puts indent("global_prefix: '#{get_global_prefix(source_company)}'")
    puts indent("global_prefix_delimiter: '#{get_global_prefix_delimiter}'")
    puts indent("adjust_point_activities: #{adjust_point_activities?}")
    prompt_for_continuation
  end

  task check_uniqueness_constraints: :environment do
    source_company, destination_company = get_source_and_destination_company_from_env!
    puts "Checking uniqueness constraints...\n"

    additional_prefixes = prefixes_that_affect_uniqueness_constraints(source_company)
    additional_attrs = attrs_that_affect_uniqueness_constraints(source_company)
    constraints = {
      migration: {
        User        => :employee_id,
        Tag         => :name,
        Badge       => { attr: :short_name }.merge(additional_prefixes[:badge]),
        CompanyRole => { attr: :name }.merge(additional_prefixes[:company_role]),
        Team        => { attr: :name }.merge(additional_prefixes[:team])
      },
      creation: {
        Team => { name: additional_attrs[:new_team_name] },
        CompanyRole => { name: additional_attrs[:new_company_role_name] }
      }
    }
    violations_found = check_uniqueness_violations_with_output(destination_company: destination_company,
                                                               source_company: source_company,
                                                               constraints: constraints)

    prompt_for_continuation if violations_found
  end

  class CompanyDataMigrator
    attr_reader :source_company, :source_company_id, :destination_company, :destination_company_id,
                :global_prefix, :global_prefix_delimiter,
                :prefixes, :new_attrs,
                :company_role, :team, :show_progress_output, :adjust_point_activities,
                :source_user_ids, :source_team_ids, :source_badge_ids

    def initialize(source_company:, destination_company:,
                   global_prefix:, global_prefix_delimiter:, prefixes:, new_attrs:,
                   adjust_point_activities: false, show_progress_output: true)
      @source_company, @source_company_id = source_company, source_company.id
      @destination_company, @destination_company_id = destination_company, destination_company.id
      @global_prefix = global_prefix
      @global_prefix_delimiter = global_prefix_delimiter
      @new_attrs = new_attrs
      @prefixes = prefixes
      @adjust_point_activities = adjust_point_activities
      @show_progress_output = show_progress_output
      validate! #raises error if there are any serious issues (eg, atm, multiple catalogs are not permitted)
    end

    def migrate!
      Company.transaction do
        store_necessary_source_record_ids

        log 'creating new company role'
        create_new_company_role(name: new_attrs[:new_company_role_name])

        log 'creating new team'
        create_new_team(name: new_attrs[:new_team_name])

        log 'moving recognitions'
        move_recognitions

        log 'moving users (and assigning company role and team)'
        move_users_and_assign_company_role_and_team

        log 'moving badges (with prefix) (and granting permission to new company role)'
        move_badges_and_grant_permission_to_role(get_prefix(:badge))

        log 'moving nominations'
        move_nominations

        log 'moving tasks (and granting permission to new company role)'
        move_tasks_and_grant_permission_to_role

        log 'moving teams (with prefix)'
        move_teams(get_prefix(:team))

        log 'moving rewards (with prefix)'
        move_rewards(get_prefix(:reward))

        log 'moving company roles (with prefix)'
        move_company_roles(get_prefix(:company_role))

        # log 'moving point activities'
        # move_point_activities(update_amounts: adjust_point_activities)

        log 'moving funds accounts'
        move_funds_accounts

        log 'moving remaining simple associations'
        move_remaining_simple_associations
      end
    end

    def refresh_caches
      if @point_activities_adjusted
        log 'updating user points'
        # ignore teams here to avoid the duplication per each member
        User.where(id: source_user_ids).find_each {|u| u.update_all_points!(update_teams: false) }

        log 'updating team points'
        Team.where(id: source_team_ids).find_each(&:update_all_points!)
      end

      team&.update_all_points!

      log 'updating badge caches'
      (source_badge_ids || []).each { |id| Badge.update_cache!(id) }

      log 'refreshing destination company counter caches'
      destination_company.refresh_all_counter_caches!

      log 'priming destination company caches'
      # This is slow as it primes caches for all users, as well as for their teams repeatedly (both of which are conditionally performed above)
      # SafeDelayer.delay(queue: 'caching').run(Company, destination_company_id, :prime_caches!)
      destination_company.prime_caches!(prime_user_caches: false)
    end

    def validate!
      multiple_catalogs = source_company.catalogs.length > 1 || destination_company.catalogs.length > 1
      raise "This does not currently support companies that have multiple catalogs" if multiple_catalogs
    end
    protected

    def get_prefix(model)
      {
        prefix: prefixes.dig(model, :prefix) || global_prefix,
        delimiter: prefixes.dig(model, :delimiter) || global_prefix_delimiter
      }
    end

    # needed for refresh_caches() method fired in the end
    def store_necessary_source_record_ids
      if adjust_point_activities
        @source_user_ids = source_company.users.pluck(:id)
        @source_team_ids = source_company.teams.pluck(:id)
      end
      @source_badge_ids = source_company.badges.pluck(:id)
    end

    def create_new_company_role(name:)
      @company_role = CompanyRole.create!(company: destination_company, name: name)
    end

    def create_new_team(name:)
      @team = Team.new(name: name, company: destination_company, network: destination_company.domain)
      @team.save!
    end

    def move_recognitions
      source_company.sent_recognitions.update_all(sender_company_id: destination_company_id)
      Recognition.where(authoritative_company_id: source_company_id).update_all(authoritative_company_id: destination_company_id)
      
      RecognitionRecipient
        .where(recipient_company_id: source_company_id)
        .update_all(recipient_company_id: destination_company_id, recipient_network: destination_company.domain)
      RecognitionRecipient
        .where(sender_company_id: source_company_id)
        .update_all(sender_company_id: destination_company_id)

      # need to adjust point activities here since they are tied
      move_point_activities(update_amounts: adjust_point_activities)
    end

    def move_users_and_assign_company_role_and_team
      users = source_company.users
      user_ids = source_company.users.pluck(:id)

      # Unique index Note (employee_id): This will raise Mysql Error for duplicate employee_ids
      users.update_all(company_id: destination_company_id, network: destination_company.domain)

      # These are created after moving users in order to prevent different-company validation error in UserTeam
      create_bulk_user_associations(user_ids, company_role.id, model: UserCompanyRole)
      create_bulk_user_associations(user_ids, team.id, model: UserTeam)
    end

    def move_badges_and_grant_permission_to_role(prefix: nil, delimiter: global_prefix_delimiter)
      source_company.badges.non_anniversary.each do |badge|
        badge.grant_permission_to_roles(:send, [company_role])
      end

      add_attribute_prefix(prefix, delimiter: delimiter, attr: :short_name, records: source_company.badges) if prefix.present?
      replace_source_company_id_for(Badge)
    end

    def move_nominations
      Nomination.where(recipient_company: source_company).update_all(recipient_company_id: destination_company_id)
      NominationVote.where(sender_company: source_company).update_all(sender_company_id: destination_company_id)
    end

    def move_tasks_and_grant_permission_to_role
      source_company.tasks.find_each do |task|
        task.grant_permission_to_roles(:send, [company_role])
      end

      replace_source_company_id_for(Tskz::Task, Tskz::CompletedTask, Tskz::TaskSubmission)
    end

    def move_teams(prefix: nil, delimiter: global_prefix_delimiter)
      add_attribute_prefix(prefix, delimiter: delimiter, attr: :name, records: source_company.teams) if prefix.present?
      replace_source_company_id_and_network_for(Team)
    end

    def move_rewards(prefix: nil, delimiter: global_prefix_delimiter)
      add_attribute_prefix(prefix, delimiter: delimiter, attr: :title, records: source_company.rewards) if prefix.present?
      replace_source_company_id_for(Reward, Redemption)
    end

    def move_funds_accounts
      # only one primary funds_account is allowed per company
      if destination_company.funds_accounts.primary.exists?
        source_company.funds_accounts.where(is_primary: true).update_all(is_primary: false)
      end
      replace_source_company_id_for(Rewards::FundsAccount)
    end

    # Unique index Note: This will raise Mysql Error for duplicate company_roles after prefix (unlikely though)
    def move_company_roles(prefix: nil, delimiter: global_prefix_delimiter)
      add_attribute_prefix(prefix, delimiter: delimiter, attr: :name, records: source_company.company_roles) if prefix.present?
      replace_source_company_id_for(CompanyRole)
    end

    def move_point_activities(update_amounts: false)
      if update_amounts
        source_ptc_ratio = source_company.catalogs.first.points_to_currency_ratio
        destination_ptc_ratio = destination_company.catalogs.first.points_to_currency_ratio
        ratios = [source_ptc_ratio, destination_ptc_ratio]
        if ratios.all?(&:present?) && ratios.uniq == ratios
          diff_factor = destination_ptc_ratio / source_ptc_ratio
          PointActivity.where(company: source_company).update_all("amount = amount * #{diff_factor}") # implicit rounding
          @point_activities_adjusted = true
        end
      end

      replace_source_company_id_and_network_for(PointActivity)
      replace_source_company_id_for(PointActivityTeam)
    end

    def move_remaining_simple_associations
      replace_source_company_id_for(UserRole, Campaign, Tag, LineItem)
    end

    private

    # Uses activerecord-import gem
    #   Note: Use import() with {validate: false} to skip validations
    def create_bulk_user_associations(user_ids, association_id, model:, column_name: nil)
      column_name ||= model.to_s.underscore.delete_prefix('user_').concat('_id')
      association_values = user_ids.map {|user_id| [user_id, association_id] }
      association_columns = [:user_id, column_name.to_sym]

      model.import!(association_columns, association_values)
    end

    def replace_source_company_id_and_network_for(*klasses)
      replace_source_company_id_for(*klasses)
      replace_source_company_network_for(*klasses)
    end

    def replace_source_company_network_for(*klasses)
      klasses.each do |klass|
        klass.where(network: source_company.domain).update_all(network: destination_company.domain)
      end
    end

    def replace_source_company_id_for(*klasses)
      klasses.each do |klass|
        klass.where(company_id: source_company_id).update_all(company_id: destination_company_id)
      end
    end

    def add_attribute_prefix(prefix, delimiter:, attr:, records:)
      records.update_all("#{attr}=CONCAT('#{prefix.strip}#{delimiter}',#{attr})")
    end

    # output with indentation and formatting
    def log(text)
      spaces = 4
      puts "#{' ' * spaces}#{text}..." if show_progress_output
    end
  end

  def get_source_and_destination_company_from_env!
    source_company_id = ENV['source_company_id'] or raise ArgumentError, 'no source company specified'
    destination_company_id = ENV['destination_company_id'] or raise ArgumentError, 'no destination company specified'

    raise ArgumentError, 'source & destination companies are the same' if source_company_id == destination_company_id

    [Company.find(source_company_id), Company.find(destination_company_id)]
  end

  def prompt_for_continuation
    input = nil
    prompt = lambda do
      print "Continue? (y/n): "
      input = STDIN.gets.chomp
    end
    prompt.call while input.blank?
    puts
    abort "\nMigration Cancelled." unless input.downcase.in?(%w[y yes])
  end

  def check_uniqueness_violations_with_output(destination_company:, source_company:, constraints:)
    violation_detected = false
    creation_conflict_subheader_printed = false
    migration_conflict_subheader_printed = false

    # checks violations when creating new records with given attrs (eg. initial role and team)
    constraints[:creation].each do |model, attrs|
      conflicting_records = model.where({ company_id: destination_company.id }.merge(attrs))
      next unless conflicting_records.present?

      violation_detected ||= true
      attrs = attrs.keys
      formatted_attrs = attrs.length == 1 ? ":#{attrs.last}" : attrs
      puts indent('Creation conflicts: (for new records used for grouping source users)') unless creation_conflict_subheader_printed
      creation_conflict_subheader_printed ||= true
      puts indent("Found conflicting #{model} in the source company: (#{formatted_attrs} not unique)", 2)
      puts indent(conflicting_records.select(:id, attrs).map(&:attributes), 3)
      puts
    end

    # checks violations when moving existing records
    constraints[:migration].each do |model, attr_obj|
      source_company_attr_query = model.where(company_id: source_company.id)
      has_prefix = attr_obj.is_a?(Hash)
      if has_prefix # test against prefixed values
        attr, prefix, delimiter = attr_obj.values_at(:attr, :prefix, :delimiter)
        source_company_attrs = source_company_attr_query.pluck(attr).map do |val|
          "#{prefix}#{delimiter}#{val}"
        end
      else
        attr = attr_obj
        prefix, delimiter = [nil] * 2
        source_company_attrs = source_company_attr_query.select(attr)
      end
      conflicting_records = model.where(company_id: destination_company.id, attr => source_company_attrs)
      next unless conflicting_records.present?

      violation_detected ||= true
      count = conflicting_records.length
      model_name = model.to_s.pluralize(count)
      conflicting_attr_info = "(:#{attr} not unique #{'after prefix' if has_prefix})"
      puts indent('Migration conflicts:') unless migration_conflict_subheader_printed
      migration_conflict_subheader_printed ||= true
      puts indent("Found #{count} conflicting #{model_name} in the source company: #{conflicting_attr_info}", 2)
      puts indent(conflicting_records.select(:id, attr).map(&:attributes), 3)
      puts
    end

    violation_detected
  end

  def get_global_prefix(source_company)
    ENV['global_prefix'] || "[#{source_company.name}]"
  end

  def get_global_prefix_delimiter
    ENV['global_prefix_delimiter'] || ' '
  end

  def adjust_point_activities?
    ENV['adjust_point_activities'] == 'true'
  end

  def refresh_caches?
    ENV['refresh_caches'] != 'false'
  end

  # this is a common place for storing the prefixes that also affect uniqueness constraints
  # so that the constraint-checking (pre-requisite task) still works as expected after these value are modified
  def prefixes_that_affect_uniqueness_constraints(source_company)
    default = default_prefix_hash(source_company)
    {
      badge:        default,
      company_role: default,
      team:         default
    }
  end

  # Similar to :prefixes_that_affect_uniqueness_constraints, but this is for creation attributes instead of migration
  def attrs_that_affect_uniqueness_constraints(source_company)
    default_prefix = get_global_prefix(source_company)
    {
      new_company_role_name: "#{default_prefix} Users",
      new_team_name: "#{default_prefix}"
    }
  end

  def get_prefixes(company)
    prefixes_not_affecting_constraints = {
      rewards: default_prefix_hash(company)
    }

    prefixes_affecting_constraints = prefixes_that_affect_uniqueness_constraints(company)
    prefixes_not_affecting_constraints.merge(prefixes_affecting_constraints)
  end

  def default_prefix_hash(company)
    default_prefix = get_global_prefix(company)
    default_delimiter = get_global_prefix_delimiter

    {  prefix: default_prefix, delimiter:  default_delimiter }
  end

  def separator_line
    "\n#{'*' * 111}"
  end

  def indent(str, times = 1)
    spaces = 4
    prefix = ' ' * spaces * times
    prefix + str.to_s
  end

end
