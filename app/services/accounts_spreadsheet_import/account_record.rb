# frozen_string_literal: true

module AccountsSpreadsheetImport
  class AccountRecord
    include ActiveModel::Model
    include UserSync::SyncFilters

    attr_accessor :user
    attr_accessor :data_sheet_schema
    attr_accessor :errors, :warnings

    # See AccountsSpreadsheetImport::AccountRecordBuilder.new(attrs).account_record for attrs that are sent to this class.
    def initialize(data_sheet_schema, attributes = {})
      attributes.each do |key, value|
        self.class.send :attr_accessor, key
        instance_variable_set "@#{key}", value
      end

      @data_sheet_schema = data_sheet_schema
      @errors = ActiveModel::Errors.new(self)
      @warnings = ActiveModel::Errors.new(self)
    end

    #
    # Active sync filters can be set for attributes (that are dynamically set in `initialize` method in this class).
    # Apart from obvious attributes that are processed in string form like (say) country, or job_title, attributes that
    # are stored as Array like company roles and team names can also be used (albeit with a little bit of caution while
    # setting up the filter rule).
    # Eg:
    # { spreadsheet_import:
    #   {
    #     role_names: ["notIn", ["skipMe", "purged"]],
    #     job_title: ["equals", "Retired"]
    #   }
    # }
    #
    def skip_processing?
      active_sync_filters.present? && !user_matches_all_filters?(self, active_sync_filters)
    end

    def find_or_create_user(send_invitation:, update_only:, user_that_adds_new_users:)
      if email.blank?
        if company_allows_phone_authentication?
          errors.add(:phone, "Phone or email can not be blank.") if phone.blank?
        else
          errors.add(:email, "Email can not be blank.")
        end
        return nil if errors[:email].present? || errors[:phone].present?
      end

      self.user = get_user_from_db
      return self.user if self.user.present?

      # User not found in db - try to create one.
      if update_only
        errors.add(:email, "Update only chosen: User with the given email was not found and will be ignored.")
      else
        if false && send_invitation
          # Invite user by email
          # user = user_that_adds_new_users.invite!(email, nil, company: company, skip_same_domain_check: true, bypass_disable_signups: true)
          # user = user.first
        else
          # Add user without invite
          phone_or_email = must_deduce_user_using_phone? ? phone : email
          self.user = user_that_adds_new_users.add_user_without_invite!(phone_or_email, company: company)
        end

        # user is always added to network of their domain
        # so move to specified domain if necessary
        unless self.user.persisted?
          unless self.user.save
            self.user.errors.each do |key, value|
              # Put appropriate errors in appropriate keys.
              # If an error is outside the scope of account record, put it in :base.
              error_key = key.in?(data_sheet_schema.attributes_to_upsert) ? key : :base
              errors.add(error_key, self.user.errors.full_message(key, value))
            end
            self.user = nil
          end
        end

        # if user.network != company.domain
        #   puts "Moving user from #{user.network} to #{company.domain}"
        #   user.move_company_to!(c)
        # end

      end
      self.user
    end

    def process_attributes
      return if user.blank?

      process_start_date
      process_birthday
      process_roles!
      process_teams!
      upsert_user_attributes!
    end

    def status
      if warnings.present?
        :saved_but_require_attention
      elsif errors.present?
        :failed
      end
    end

    def process_manager!
      return if self.user.blank?

      if self.manager_email.blank?
        user.update_column(:manager_id, nil)
      else
        manager = company.users.find_by(email: self.manager_email)
        if manager.present?
          self.user.update_column(:manager_id, manager.id)
        else
          self.warnings.add(:manager_email, "Manager with the email was not found.")
        end
      end
    end

    # Method override.
    def provider
      :spreadsheet_import
    end

    private

    def process_start_date
      return if self.start_date.blank?

      start_date_datetime = AccountsSpreadsheetImport::StartDateString.to_datetime(self.start_date)
      if start_date_datetime.present?
        self.start_date = start_date_datetime
      else
        warnings.add(:start_date, "Start date is invalid.")
      end
    end

    def process_birthday
      return if self.birthday.blank?

      birthday_datetime = AccountsSpreadsheetImport::BirthdayDateString.to_datetime(birthday)
      if birthday_datetime.present?
        self.birthday = birthday_datetime
      else
        warnings.add(:birthday, "Birthday is invalid.")
      end
    end

    def process_teams!
      return unless data_sheet_schema.header_cell_for_attribute(:team_names).present_in_sheet

      self.team_names = self.team_names || []

      teams_provided = self.team_names.reject(&:blank?).map do |team_name|
        # ensure company has team setup before adding to user
        company.teams.find_or_create_by!(name: team_name)
      end

      teams_to_be_detached_from_user = user.teams - teams_provided
      teams_to_be_attached_to_user = teams_provided - user.teams

      teams_to_be_detached_from_user.each { |team| user.teams.remove(team) }
      teams_to_be_attached_to_user.each { |team| user.teams.add(team) }
    end

    def process_roles!
      return unless data_sheet_schema.header_cell_for_attribute(:role_names).present_in_sheet

      self.role_names = self.role_names || []

      roles_provided = self.role_names.reject(&:blank?).map do |role_name|
        # ensure company has role setup before adding to user
        company.company_roles.find_or_create_by!(name: role_name)
      end

      roles_to_be_detached_from_user = user.company_roles - roles_provided
      roles_to_be_attached_to_user = roles_provided - user.company_roles

      roles_to_be_detached_from_user.each { |role| user.company_roles.remove(role) }
      roles_to_be_attached_to_user.each { |role| user.company_roles.add(role) }
    end

    def upsert_user_attributes!
      attrs = {}

      # Check if required attributes are present. If they are present, assign them to user object. If they are not, flag
      # the row as problematic with message `<attribute> is blank`.
      required_user_attributes_for_user_update.each do |attribute|
        if self.send(attribute).present?
          attrs[attribute] = self.send(attribute)
        else
          self.warnings.add(attribute, "#{attribute.to_s.humanize} is blank.")
        end
      end

      optional_user_attributes_for_user_update.each do |attribute|
        # Do not assign an attribute to the user, if the attribute has an error.
        next unless self.errors[attribute].blank? && self.warnings[attribute].blank?

        # Overwrite attribute with whatever is in the relevant datasheet cell; this implies that if the relevant cell
        # is blank, null-ify the attribute.
        attrs[attribute] = self.send(attribute)
      end

      if self.user.disabled?
        attrs[:status] = self.user.last_non_disabled_status
        attrs[:disabled_at] = nil
      end

      attrs[:skip_name_validation] = true
      self.user.assign_attributes(attrs)

      if self.user.changed?
        unless self.user.save
          self.user.errors.each do |key, _value|
            # Put errors in appropriate keys. If error is outside the scope of account record, put it in :base
            error_key = key.in?(data_sheet_schema.attributes_to_upsert) ? key : :base
            next if self.errors[error_key].present?

            problem_type = (optional_user_attributes_for_user_update.include?(key) && key != :employee_id) ? :warnings : :errors
            self.send(problem_type).add(error_key, self.user.errors.full_messages_for(key).join(". "))
          end
        end
      end
    end

    def required_user_attributes_for_user_update
      attributes = data_sheet_schema.attributes_required
      attributes.delete(:email) if must_deduce_user_using_phone?
      attributes
    end

    def optional_user_attributes_for_user_update
      data_sheet_schema.attributes_to_upsert_directly_in_user_table - required_user_attributes_for_user_update
    end

    def get_user_from_db
      if employee_id.present?
        UserFinder::ByEmployeeIdOrEmail.new(company, employee_id: employee_id, email: email).find
      elsif can_deduce_user_using_phone?
        UserFinder::ByEmailOrPhone.new(company, phone: phone, email: email).find
      else
        UserFinder::ByEmail.new(company, email: email).find
      end
    end

    def must_deduce_user_using_phone?
      can_deduce_user_using_phone? && self.email.blank?
    end

    def can_deduce_user_using_phone?
      company_allows_phone_authentication? && self.phone.present?
    end

    def company_allows_phone_authentication?
      company.settings.allow_phone_authentication?
    end

    class UserFinder
      class Base
        attr_accessor :company, :findables

        def initialize(company, findables = {})
          @company = company
          @findables = findables
        end

        def users_scope
          User.where(company_id: company.id)
        end
      end

      class ByEmail < Base
        def find
          email = findables[:email]
          email.blank? ? nil :  users_scope.find_by(email: email)
        end
      end

      class ByEmployeeIdOrEmail < Base
        def find
          by_employee_id || by_email
        end
        
        def by_employee_id
          if (employee_id = findables[:employee_id]).present?
            users_scope.find_by(employee_id: employee_id)
          end
        end

        def by_email
          if (email = findables[:email]).present?
            users_scope.find_by(email: email, employee_id: nil)
          end
        end
      end

      class ByEmailOrPhone < ByEmail
        def find
          super || by_phone
        end
        
        def by_phone
          if (phone = findables[:phone]).present?
            users_scope.find_by(phone: phone)
          end
        end
      end
    end

  end
end
