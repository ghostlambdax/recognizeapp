# frozen_string_literal: true

require 'will_paginate/array'
class RecognitionsDatatable < Litatable
  attr_reader :report

  COLUMN_SPEC = [
    {attribute: :html_link, export_format: :removeLinkKeepHref, orderable: false, title: proc { I18n.t('dict.link') }},
    {attribute: :date, orderable: true, sort_column: 'recognitions.created_at', title: proc { I18n.t('dict.date') }},
    {attribute: :sender_employee_id, colvis: :hide, orderable: true, sort_column: 'senders_recognitions.employee_id', title: "Sender Employee Id"},
    {attribute: :sender_first_name, colvis: :hide, orderable: true, sort_column: 'senders_recognitions.first_name', title: "Sender First Name"},
    {attribute: :sender_last_name, colvis: :hide, orderable: true, sort_column: 'senders_recognitions.last_name', title: "Sender Last Name"},
    {attribute: :sender_email, colvis: :hide, orderable: true, sort_column: 'senders_recognitions.email', title: proc { I18n.t("forms.sender_email") }},
    {attribute: :sender_name, orderable: false, title: "Sender Full Name"},
    {attribute: :reference_recipient_employee_id, colvis: :hide, orderable: true, sort_column: 'users.employee_id', title: "Recipient Employee Id"},
    {attribute: :reference_recipient_first_name, colvis: :hide, orderable: true, sort_column: 'users.first_name', title: "Recipient First Name"},
    {attribute: :reference_recipient_last_name, colvis: :hide, orderable: true, sort_column: 'users.last_name', title: "Recipient Last Name"},
    {attribute: :reference_recipient_email, colvis: :hide, orderable: true, sort_column: 'users.email', title: proc { I18n.t("forms.recipient_email") }},
    {attribute: :reference_recipient_full_name, orderable: false, title: "Recipient Full Name"},
    {attribute: :badge, orderable: true, sort_column: 'badges.short_name', title: proc { I18n.t("forms.badge") }},
    {attribute: :message, orderable: false, title: proc { I18n.t("forms.message") }},
    {attribute: :quick_nomination, export_format: :formatSelect, orderable: false, title: proc { I18n.t("dict.nominate") }, if: proc { view.params[:status] == "approved" && company.allow_quick_nominations?}},
    {attribute: :tags, orderable: false, title: proc { company.custom_labels.recognition_tags_label }},
    {attribute: :reference_recipient_team_names, orderable: false, title: proc { I18n.t("forms.teams") }},
    {attribute: :points, orderable: false, title: proc { I18n.t("forms.points") }, if: proc { view.params[:status] != "denied" }},
    {attribute: :recognized_team, orderable: false, title: proc { I18n.t("forms.recognized_team") }, if: proc { view.params[:status] == "approved" }}, # only recognize teams for non-approval badges, so won't show up on pending/denied
    {attribute: :reference_recipient_manager_name, orderable: false, title: proc { I18n.t('dict.recipient_manager') }},
    {attribute: :reference_recipient_manager_email, colvis: :hide, orderable: false, title: proc { I18n.t('dict.recipient_manager_email') }},
    {attribute: :is_private, orderable: false, title: proc { I18n.t('dict.private') }},
    {attribute: :status, orderable: false, title: proc { I18n.t("dict.status") }},
    {attribute: :sender_department, orderable: true, sort_column: 'senders_recognitions.department', title: proc { I18n.t("dict.sender_department") }},
    {attribute: :sender_country, orderable: true, sort_column: 'senders_recognitions.country', title: proc { I18n.t("dict.sender_country") }},
    {attribute: :reference_recipient_department, orderable: true, sort_column: 'users.department', title: proc { I18n.t("dict.recipient_department") }},
    {attribute: :reference_recipient_country, orderable: true, sort_column: 'users.country', title: proc { I18n.t("dict.recipient_country") }},
  ].freeze

  def initialize(view, company, report)
    @report = report
    super(view, company)
  end

  def filters
    return if params[:status] == "pending_approval"

    role_choices = [["All", nil]]
    role_choices = company.company_roles.inject(role_choices) { |set, role| set << [role.name, role.id]; set }

    countries = company.users.pluck(:country).uniq
    country_choices = [["All", nil]] | countries.map { |name| [name, name] unless name.nil?}.compact

    departments = company.users.pluck(:department).uniq
    department_choices = [["All", nil]] | departments.map { |name| [name, name] unless name.nil?}.compact

    [
      FilterRowGroup.new(
        SelectFilter.new("filter[sender_company_role][id]", "Sender Role", role_choices, id: "filter_company_role_id"),
        SelectFilter.new("filter[sender_department][id]", "Sender Department", department_choices, id: "filter_department"),
        SelectFilter.new("filter[sender_country][id]", "Sender Country", country_choices, id: "filter_country"),
      ),
      FilterRowGroup.new(
        SelectFilter.new("filter[receiver_company_role][id]", "Receiver Role", role_choices, id: "filter_company_role_id"),
        SelectFilter.new("filter[receiver_department][id]", "Receiver Department", department_choices, id: "filter_department"),
        SelectFilter.new("filter[receiver_country][id]", "Receiver Country", country_choices, id: "filter_country"),
      )
    ]
  end

  def group_rows?
    true
  end

  def group_rows_by
    :slug
  end

  def namespace
    "recognitions"
  end

  def serialize_to_hash  
    super.merge({report: report.id})
  end

  def serializer
    RecognitionRecipientSerializer
  end

  def custom_serializer_opts
    is_export = (params[:action] == 'queue_export')
    { is_export: is_export }
  end

  def allow_export
    params[:status] != "pending_approval"
  end

  def server_side_export
    true
  end

  def default_order
    "[[ 1, \"desc\" ]]"
  end

  private

  def all_records
    report.recognitions
  end

  def filtered_records
    recognitions = all_records
    recognitions = recognitions.order(sort_columns_and_directions)

    search_term = params.dig(:search, :value)
    if search_term.present?
      recognitions = RecognitionSearch.new(recognitions, company, view).search(search_term)
    end

    recognitions.paginate(page: page, per_page: per_page)
  end

  class RecognitionSearch
    attr_reader :recognitions, :company, :view
    def initialize(recognitions, company, view)
      @recognitions = recognitions
      @company = company
      @view = view
    end

    def search(terms)
      search_value = Regexp.new(Regexp.escape(terms), 'i')

      matches = recognitions.select do |r|
        matched = false
        matched ||= r.slug.match(search_value)
        matched ||= r.message&.match(search_value)
        matched ||= view.status_label_for_datatable(r).match(search_value)
        matched ||= r.badge.short_name.match(search_value)
        matched ||= r.sender&.employee_id&.match(search_value)
        matched ||= r.sender&.first_name&.match(search_value)
        matched ||= r.sender&.last_name&.match(search_value)
        matched ||= r.sender_name&.match(search_value)
        matched ||= r.sender_email&.match(search_value)
        matched ||= r.sender&.department&.match(search_value)
        matched ||= r.sender&.country&.match(search_value)

        matched ||= r.reference_recipient&.employee_id&.match(search_value)
        matched ||= r.reference_recipient&.first_name&.match(search_value)
        matched ||= r.reference_recipient&.last_name&.match(search_value)
        matched ||= r.reference_recipient&.full_name&.match(search_value)
        matched ||= r.reference_recipient&.email&.match(search_value)
        matched ||= r.reference_recipient && r.reference_recipient_teams.find { |team| team.name.match(search_value) }
        matched ||= r.reference_recipient&.department&.match(search_value)
        matched ||= r.reference_recipient&.country&.match(search_value)

        matched ||= begin
          @company.include_tag_column_in_recognition_datatable? &&
            r.reference_recognition_tags.map(&:tag_name).detect { |tag_name| tag_name.match(search_value) }.present?
        end

        matched
      end

      matches
    end
  end
end
