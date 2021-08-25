# frozen_string_literal: true

class UsersDatatable < Litatable
  COLUMN_SPEC = [
    {attribute: :first_column, orderable: true, colvis: :hide, sort_column: proc { company.uses_employee_id? ? "users.employee_id" : "users.id" }},
    {attribute: :first_name, orderable: true, export_format: :removeLink},
    {attribute: :last_name, orderable: true, export_format: :removeLink},
    {attribute: :email, orderable: true, export_format: :nodeTextEmail},
    {attribute: :phone, orderable: true, colvis: :hide},
    {attribute: :user_principal_name, orderable: true, colvis: :hide, if: proc { company.settings.auth_via_user_principal_name? }},
    {attribute: :network, orderable: true, colvis: :hide, if: proc { company.in_family? }},
    {attribute: :manager, orderable: false, colvis: :hide, export_format: :formatSelect},
    {attribute: :teams, orderable: false, title: proc { I18n.t("company_admin.accounts.company_teams") }, colvis: :hide, export_format: :formatSelect},
    {attribute: :roles, orderable: false, title: proc { I18n.t("company_admin.accounts.system_roles") }, colvis: :hide},
    {attribute: :promote_demote_link, orderable: false, title: "Admin", colvis: :hide, export_format: :removeLink},
    {attribute: :company_roles, orderable: false, title: proc { I18n.t("company_admin.accounts.company_roles") }, colvis: :hide, export_format: :formatSelect},
    {attribute: :dept, orderable: true, title: proc { I18n.t("dict.department") }, colvis: :hide, sort_column: "users.department"},
    {attribute: :country, orderable: true, title: proc { I18n.t("dict.country") }, colvis: :hide},
    {attribute: :status, orderable: true, export_format: :formatStatusCol},
    {attribute: :created_at, orderable: true, title: proc { I18n.t("dict.created_at") }, colvis: :hide},
    {attribute: :edit_link, orderable: false, title: proc { I18n.t("dict.edit") }, export: false},
    {attribute: :activate_link, orderable: false, title: proc { I18n.t("dict.actions") }, export: false},
    {attribute: :reset_password_links, orderable: false, title: proc { I18n.t("dict.reset_password_links") }, colvis: :hide, export_format: :userPasswordResetLink}
  ].freeze

  CUSTOM_FIELDS_COLUMNS_LOCATION = %i[before created_at].freeze

  def all_records
    User
      .joins(:company)
      .includes(:company, :authentications, :manager, {user_company_roles: :company_role}, {user_teams: :team})
      .where(company_id: company.id)
      .references(:company_roles, :teams)
  end

  def column_spec
    # super duper
    @column_spec ||= begin
      cs = super.dup
      if custom_fields_column_specs.present?
        where, which = CUSTOM_FIELDS_COLUMNS_LOCATION
        reference_position = cs.find_index { |c| c[:attribute].to_sym == which.to_sym }

        # reference position may not be available
        # for example users anniversary datatable doesn't include :created_at field
        # If so, just make reference position be the last column
        reference_position = cs.length if reference_position.blank?

        target_position = where == :before ? reference_position : reference_position + 1
        cs.insert(target_position, *custom_fields_column_specs)
      end
      cs
    end
  end

  def custom_fields_column_specs
    # [{attribute: :fb_workplace_id, orderable: false, title: "Fb Workplace Yo"}]
    company.custom_field_mappings.map do |cfm|
      {attribute: cfm.key, orderable: false, title: cfm.name, colvis: :hide}
    end
  end

  def filtered_records
    ar_connection = ActiveRecord::Base.connection
    statuses = User::STATES.map(&:to_s)
    user_states_to_include = params[:status].present? ? params[:status] & statuses : statuses

    where_clauses = []

    if params[:search].present? && params[:search][:value].present?

      search_tokens = params[:search][:value].split(" ").map(&:strip)
      search_tokens = (search_tokens - user_states_to_include).join(" ")

      search = ar_connection.quote("%#{search_tokens}%")
      # http://cha1tanya.com/2013/10/14/conditional-where-in-rails.html
      columns_to_search_in = [
          "users.first_name",
          "users.last_name",
          "users.email",
          "users.phone",
          "company_roles.name",
          "teams.name",
          "users.department",
          "users.country"
      ]
      columns_to_search_in.unshift("users.employee_id") if company.uses_employee_id?

      company.custom_field_mappings.each do |cfm|
        columns_to_search_in << "users.#{cfm.key}"
      end

      where_clauses << columns_to_search_in.map { |r| " #{r} like #{search} " }.join("or")

    end

    params[:status] && params[:status].reject!(&:blank?)
    if params[:status].present?
      quoted = user_states_to_include.map { |s| ar_connection.quote(s) }.join(",")
      status_where_clause = "users.status IN (#{quoted})"
    end

    case sort_columns
      when ["users.manager"]
        order_clause = "managers_users.first_name #{sort_directions[0]}"
      else
        order_clause = sort_columns_and_directions.to_s
    end

    users = User
      .joins(:company)
      .includes(:company, :authentications, :company_roles, :user_roles, :teams, :manager, {user_company_roles: :company_role}, {user_teams: :team})
      .where(company_id: company.id)
    users = users.where(where_clauses.join(" AND ")) if where_clauses.present?
    users = users.where(status_where_clause) if status_where_clause.present?

    users
      .order(order_clause)
      .paginate(page: page, per_page: per_page)
  end

  def filters
    choices = User::STATES.map { |s| [s.to_s.humanize, s] }
    selected = [:active]
    [SelectFilter.new(:status, "Filter by Status", choices, multiple: true, selected: selected, id: "filter-by-status")]
  end

  def export_filename
    "#{company.domain}-users"
  end

  def first_column
    company.uses_employee_id? ? "employee_id" : "id"
  end

  def namespace
    "accounts"
  end

  def serializer
    UserRow
  end

  def server_side_export
    true
  end

  class UserRow < ActiveModel::Serializer
    attributes   :id, :employee_id, :first_name, :last_name, :email, :phone, :manager,
                 :teams, :roles, :promote_demote_link, :company_roles, :status,
                 :created_at, :edit_link, :activate_link, :user_principal_name,
                 :dept, :country, :DT_RowId, :reset_password_links

    def attributes(*args)
      hash = super
      hash[:network] = user.network if user.company.in_family?
      user.company.custom_field_mappings.each do |cfm|
        hash[cfm.key] = user.send(cfm.key)
      end
      hash
    end

    def activate_link
      context.activate_link(user)
    end

    def reset_password_links
      context.reset_password_links(user)
    end

    def created_at
      context.created_at(user)
    end

    def company_roles
      context.select_company_roles(user)
    end

    def current_user
      context.current_user
    end

    def DT_RowId
      "user_row_#{user.id}"
    end

    def edit_link
      context.edit_link(user)
    end

    def email
      context.email_with_login_link(user)
    end

    def phone
      context.user_phone(user)
    end

    def first_name
      context.first_name_link(user)
    end

    def last_name
      context.last_name_link(user)
    end

    def manager
      context.select_manager(user)
    end

    def promote_demote_link
      context.promote_demote_link(user)
    end

    def teams
      context.select_teams(user)
    end

    def roles
      context.roles(user)
    end

    def status
      context.status(user)
    end

    def dept
      context.department(user)
    end

    def country
      context.country(user)
    end

    def user
      @object
    end

    private

    def method_missing(method, *args, &block)
      if context.respond_to?(method)
        context.send(method, *args, &block)
      else
        super
      end
    end
  end
end
