# FIXME: When attr_masker gem gets its act together and makes a global config possible, 
#        this should be moved to config/ instead of config/initalizers

# HACK: Due to Attr_masker not guaranteeing load order (due to use of ActiveRecord::Base.descendants)
#       try to force CompanyDomain as this is the very first thing that must be processed
# require_relative '../../app/models/company_domain.rb'

# FIXME: Turn off for now. This is only needed in development env when producing masked data
#        When next needed, hopefully the attr_masker gem has advanced to provide
#        a more proper centralized configuration.

# TODO: 
# * clear oauth_applications and oauth_access_tokens
# * update recognition_recipients.recipient_network
# * clear out or mask: support_emails, contact lists, authentications, chat_messages, chat_thread, subscriptions, plans
# * mask user principal name, employee_id(?)
if false
  CompanyDomain


  leave_alone_domains = ["recognizeapp.com", "planet.io", "redwoodhealthclinic.com"]
  leave_alone_company_ids = Company.where(domain: leave_alone_domains).map(&:id)
  shakespeare = ->(model:,**) { [Faker::Quotes::Shakespeare.hamlet_quote,Faker::Quotes::Shakespeare.romeo_and_juliet_quote][rand(2)] }

  def nullify(fields, condition)
    fields.each do |field|
      attr_masker field, if: condition, masker: ->(**) { nil }
    end
  end

  # This needs to be above company because
  # Company will reference one of these domains
  # If CompanyDomain came after, it would be impossible to know which CompanyDomain record
  # should be the one that matches the Company record and which should be an alternate.
  CompanyDomain.class_eval do
    condition = ->(cc) { leave_alone_company_ids.exclude?(cc.company_id) }
    attr_masker :domain, if: condition, masker: ->(model:,**) { "#{Faker::Internet.domain_word}-#{Faker::Internet.domain_word}#{rand(100)}.fake.#{Faker::Internet.domain_suffix}" }
  end

  Company.class_eval do
    condition = ->(company) { leave_alone_domains.exclude?(company.domain) }

    attr_masker :name, if: condition, masker: ->(**) { Faker::Company.name }
    attr_masker :domain, if: condition, masker: ->(model:,**) { model.domains.first&.domain || "#{Faker::Internet.domain_word}-#{Faker::Internet.domain_word}#{rand(100)}.fake.#{Faker::Internet.domain_suffix}" }
    attr_masker :website, if: condition, masker: ->(model:,**) { model.domain } 
    attr_masker :slug, if: condition, masker: ->(model:,**) { model.domain } 

    nullify_fields = [:kiosk_mode_key, :labels, :last_accounts_spreadsheet_import_file, :last_accounts_spreadsheet_import_problematic_records_file,:microsoft_team_id]
    nullify(nullify_fields, condition)

  end

  User.class_eval do
    condition = ->(user) { leave_alone_domains.exclude?(user.network) }

    attr_masker :first_name, if: condition, masker: ->(**) { Faker::Name.first_name }
    attr_masker :last_name, if: condition, masker: ->(**) { Faker::Name.last_name }
    attr_masker :email, if: condition, masker: ->(model:,**) { "#{model.first_name[0..15]}.#{model.last_name[0..15]}@#{model.company.domain}"}
    attr_masker :network, if: condition, masker: ->(model:,**) { model.company.domain }
    # attr_masker :unique_key, unless: condition, masker: ->(model:,**) { "#{model.email}-#{model.network}"}
    attr_masker :job_title, if: condition, masker: ->(model:,**) { Faker::Job.title }
    attr_masker :slug, if: condition, masker: ->(model:,**) { "#{model.first_name}-#{model.last_name}" }

    nullify_fields = [:crypted_password, :current_login_ip, :last_login_ip, :contacts_raw,
    :yammer_id, :phone, :microsoft_graph_id, :outlook_identity_token, :display_name,
    :fb_workplace_id, :user_principal_name]
    nullify(nullify_fields, condition)
    
  end

  Badge.class_eval do
    condition = ->(badge) { leave_alone_company_ids.exclude?(badge.company_id) }

    attr_masker :name, if: condition, masker: ->(**) { Faker::Superhero.name }
    attr_masker :short_name, if: condition, masker: ->(model:,**) { model.name }
    attr_masker :long_name, if: condition, masker: ->(model:,**) { model.name }
    attr_masker :description, if: condition, masker: ->(**) { Faker::Company.bs }
    attr_masker :anniversary_message, if: condition, masker: shakespeare
    attr_masker :long_description, if: condition, masker: shakespeare
  end

  Comment.class_eval do
    condition = ->(comment) { leave_alone_company_ids.exclude?(comment.company_id) }
    attr_masker :content, if: condition, masker: shakespeare
  end

  CompanyCustomization.class_eval do
    condition = ->(cc) { leave_alone_company_ids.exclude?(cc.company_id) }
    nullify_fields = [:email_header_logo, :certificate_background, :end_user_guide, :primary_header_logo, :secondary_header_logo]
    nullify(nullify_fields, condition)
  end

  CompanyRole.class_eval do
    condition = ->(cr) { leave_alone_company_ids.exclude?(cr.company_id) }
    attr_masker :name, if: condition, masker: ->(**) { "#{Faker::Job.title} #{Faker::Job.position} for #{Faker::Job.field}" }
  end

  CompanySetting.class_eval do
    condition = ->(cs) { leave_alone_company_ids.exclude?(cs.company_id) }
    nullify_fields = [:fb_workplace_community_id,:fb_workplace_token,:fb_workplace_post_to_group_id, :yammer_sync_groups, :microsoft_graph_sync_groups, :anniversary_recognition_custom_sender_name]
    nullify(nullify_fields, condition)
  end

  Tskz::CompletedTask.class_eval do
    condition = ->(ct) { leave_alone_company_ids.exclude?(ct.company_id) }
    attr_masker :comment, if: condition, masker: shakespeare
  end

  ContactList.class_eval do
    condition = ->(cl) { leave_alone_company_ids.exclude?(cl.user&.company_id) }
    nullify_fields = [:contacts_raw]
    nullify(nullify_fields, condition)
  end

  CustomFieldMapping.class_eval do
    condition = ->(cfm) { leave_alone_company_ids.exclude?(cfm.company_id) }
    nullify_fields = [:key, :name, :provider_key, :mapped_to, :provider_type, :provider_attribute_key]
    nullify(nullify_fields, condition)
  end

  FbWorkplaceUnclaimedToken.class_eval do
    condition = ->(ut) { true }
    nullify_fields = [:token]
    nullify(nullify_fields, condition)
  end

  Rewards::FundsAccountManualAdjustment.class_eval do
    # There seem to be a few isolated cases where there can be a manual adjustment records but no
    # funds_txns records???
    condition = ->(ma) { leave_alone_company_ids.exclude?(ma.funds_txns.first&.funds_account&.company_id) }
    attr_masker :comment, if: condition, masker: shakespeare
  end

  Rewards::FundsTxn.class_eval do
    condition = ->(ft) { leave_alone_company_ids.exclude?(ft.funds_account.company_id) }
    attr_masker :description, if: condition, masker: shakespeare
  end

  LineItem.class_eval do
    condition = ->(li) { true }
    nullify_fields = [:stripe_attributes]
    nullify(nullify_fields, condition)
  end

  MsTeamsConfig.class_eval do
    condition = ->(c) { true }
    nullify_fields = [:settings]
    nullify(nullify_fields, condition)
  end

  NominationVote.class_eval do
    condition = ->(nv) { leave_alone_company_ids.exclude?(nv.sender_company_id) }
    attr_masker :message, if: condition, masker: shakespeare
  end

  # PointActivies will take forever to go row by row
  # An update all in the rake task wrapper is better
  # PointActivity.class_eval do
  #   condition = ->(pa) { pa.company_id.in?(leave_alone_company_ids) }
  #   attr_masker :network, unless: condition, masker: ->(model:,**) { Company.unscoped{ model.company.domain } }
  # end

  Recognition.class_eval do
    condition = ->(r) { leave_alone_company_ids.exclude?(r.sender_company_id) }
    denial_message_condition = ->(r) { condition.call(r) && r.denied? }
    
    attr_masker :message, if: condition, masker: shakespeare
    attr_masker :denial_message, if: denial_message_condition, masker: shakespeare
    attr_masker :message_plain, if: condition, masker: ->(model:,**) { model.message }

    nullify_fields = [:skills, :reason, :post_to_yammer_group_id]
    nullify(nullify_fields, condition)
  end

  Redemption.class_eval do
    condition = ->(r) { leave_alone_company_ids.exclude?(r.company_id) }

    nullify_fields = [:response_message, :additional_instructions]
    nullify(nullify_fields, condition)

  end

  Reward.class_eval do
    condition = ->(r) { leave_alone_company_ids.exclude?(r.company_id) }
    description_condition = ->(r) { condition.call(r) && !r.provider_reward? } # only update company custom rewards

    attr_masker :description, if: description_condition, masker: shakespeare
    
    nullify_fields = [:image, :additional_instructions]
    nullify(nullify_fields, condition)
  end

  Role.class_eval do
    condition = ->(r) { leave_alone_company_ids.exclude?(r.sender_company_id) }
    attr_masker :name, if: condition, masker: ->(**) { Faker::Job.title }
  end

  Subscription.class_eval do
    condition = ->(s) { leave_alone_company_ids.exclude?(s.company_id) }

    nullify_fields = [:email]
    nullify(nullify_fields, condition)
  end

  Tag.class_eval do
    condition = ->(s) { leave_alone_company_ids.exclude?(s.company_id) }
    attr_masker :name, if: condition, masker: ->(**) { Faker::Company.buzzword }
  end

  Tskz::TaskSubmission.class_eval do
    condition = ->(ts) { leave_alone_company_ids.exclude?(ts.company_id) }
    approval_comment_condition = ->(ts) { condition && !ts.pending?}

    attr_masker :description, if: condition, masker: shakespeare
    attr_masker :approval_comment, if: approval_comment_condition, masker: shakespeare
  end

  Tskz::Task.class_eval do
    condition = ->(t) { leave_alone_company_ids.exclude?(t.company_id) }
    attr_masker :name, if: condition, masker: ->(**) { Faker::Hacker.say_something_smart }
  end

  Team.class_eval do
    condition = ->(t) { leave_alone_company_ids.exclude?(t.company_id) }

    attr_masker :name, if: condition, masker: ->(**) { Faker::Team.name }
    attr_masker :network, if: condition, masker: ->(model:,**) { Company.unscoped { model.company.domain } }
    nullify_fields = [:microsoft_graph_id]
    nullify(nullify_fields, condition)
  end
end
