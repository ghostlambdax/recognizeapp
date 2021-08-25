# frozen_string_literal: true

require 'will_paginate/array'

# Caution! CompanyPointActivitiesDatatable inherits from UserPointActivitiesDatatable.
class CompanyPointActivitiesDatatable < UserPointActivitiesDatatable
  COLUMN_SPEC = [
    { attribute: :date, orderable: true, sort_column: "point_activities.created_at", title: proc { I18n.t("dict.date") } },
    { attribute: :user, orderable: true, sort_column: "users.email", export_format: :nodeText },
    { attribute: :activity, orderable: false, title: proc { I18n.t("dict.activity") } },
    { attribute: :amount, orderable: true, sort_column: "point_activities.amount", title: proc { I18n.t("dict.amount") } },
    { attribute: :description, orderable: false, title: proc { I18n.t("dict.description") }, export_format: :nodeText },
    { attribute: :is_redeemable, ordertable: true, sort_column: "point_activities.is_redeemable", title: proc { I18n.t("dict.is_redeemable") } }
  ].freeze

  def initialize(view, company)
    @view = view
    @company = company
  end

  def all_records
    activities = PointActivity
                   .includes(:user, recognition: :badge)
                   .references(:users, recognition: :badge)
                   .where(company_id: @company.id)
    activities = activities.order(sort_columns_and_directions.to_s) if params[:order].present?
    activities
  end

  def namespace
    'company_point_activities'
  end

  def server_side_export
    true
  end

  private

  def columns_to_search_in
    super + %w[users.first_name users.last_name users.email users.display_name]
  end
end
