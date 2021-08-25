class BulkUserUpdater
  include ActiveModel::Model

  attr_reader :company, :user, :users_to_create, :users_to_update, :params, :id
  validate :all_users_are_valid

  UPDATEABLE_ATTRS = [:first_name, :last_name, :email, :phone, :network, :job_title, :start_date, :birthday]

  def initialize(company, user)
    @company = company
    @user = user
  end

  def update(_params)
    @params = _params
    setup_users_to_create
    setup_users_to_update

    if valid?
      User.transaction do 
        users_to_create.map(&:save!)
        users_to_update.map(&:save!)
      end
      # company.delay(queue: 'caching').refresh_cached_users!
      SafeDelayer.delay(queue: 'caching').run(Company, company.id, :refresh_cached_users!)

      return true
    else
      return false
    end
  end

  def can_edit?(field)
    case field
    when :department
      user.director? && user.company.in_family?
    else
      return true
    end
  end

  def persisted?
    true
  end

  def self.attributes_for_json
    [:created_users, :updated_users]
  end

  def created_users
    return [] unless valid?

    users_to_create.select(&:persisted?).map do |u|
      {
        id: u.id,
        email: u.email,
        temporary_id: u.new_record_temporary_id,
        birthday: u.birthday,
        start_date: u.start_date,
        phone: u.phone
      }
    end
  end

  def updated_users
    valid? ? users_to_update.map{ |u| {id: u.id}.merge(user_attributes_for_row(u)) } : []
  end

  private

  def user_attributes_for_row(user)
    user.attributes.slice(*UPDATEABLE_ATTRS.map(&:to_s))
  end

  def parse_date(date, format)
    Date.strptime(date, format) rescue date
  end

  def setup_users_to_create
    set = params.inject([]) do |array, (_id, user_params)|
      if user_params[:create].present? && user_params[:create] == "1"
        user_params[:start_date] = parse_date(user_params[:start_date], "%m/%d/%Y") if user_params[:start_date].present?
        user_params[:birthday] = parse_date(user_params[:birthday], "%m/%d") if user_params[:birthday].present?
        user = User.new(user_params.slice(*UPDATEABLE_ATTRS))
        user.company = Company.find_by(domain: user_params[:network]) || @user.company# force company to the department param
        user.network = user.company.domain # force network
        user.skip_same_domain_check = true # allow external users to be added via bulk user form
        user.new_record_temporary_id = user_params[:id]
        user.bypass_disable_signups = true
        user.status = :pending_invite # dont send invites for users added via bulk interface so we can send bulk email later
        array << user
      end
      array
    end
    @users_to_create = UserCollection.new(set)    
  end

  def setup_users_to_update
    set = params.inject([]) do |array, (_id, user_params)|
      if user_params[:update].present? && user_params[:update] == "1"
        user = User.find(user_params[:id])

        requested_network = user_params[:network]
        if requested_network.present? &&
             !user.network.casecmp?(requested_network) &&
             user.domain_in_family?(requested_network)
          new_company = Company.find_by(domain: requested_network) # force company to the department param
          user.move_company_to!(new_company)
          user.reload
          user_moved_to_another_company = true
        end

        user.skip_same_domain_check = true # allow external users to be added via bulk user form
        user_params[:start_date] = parse_date(user_params[:start_date], "%m/%d/%Y") if user_params[:start_date].present?
        user_params[:birthday] = parse_date(user_params[:birthday], "%m/%d") if user_params[:birthday].present?
        user.assign_attributes(user_params.slice(*UPDATEABLE_ATTRS))
        # for nil to "" change
        user.changes.each do |k, v|
          user.clear_attribute_changes([k]) if v[0].to_s == v[1].to_s
        end
        array << user if user.changed? || user_moved_to_another_company 
      end
      array
    end
    @users_to_update = UserCollection.new(set)
  end

  def all_users_are_valid
    if (users_to_update && !users_to_update.valid?) || (users_to_create && !users_to_create.valid?)
      errors.add(:base, I18n.t('activerecord.errors.models.bulk_user_updater.all_users_are_valid', default: "Save did not complete due to the errors below."))
      # hack to get json resource to report errors on the respective collection
      errors.add(:users_to_create, "") unless users_to_create.valid?
      errors.add(:users_to_update, "") unless users_to_update.valid?
    end
  end

  class UserCollection < Array
    def valid?
      @valid ||= each(&:valid?) && !errors.present?
    end

    def errors
      @errors ||= inject({}){|hash, u| 
        id = u.persisted? ? u.to_param : u.new_record_temporary_id
        hash[id] = u.errors if u.errors.present?
        hash
      }
    end
  end
end
