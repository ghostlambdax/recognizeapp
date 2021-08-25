# frozen_string_literal: true

require 'will_paginate/array'
# Note: ManagerAdmin::RewardsRedemptionsDatatable inherits this class.
class RewardsRedemptionsDatatable < Litatable
  include DateTimeHelper

  COLUMN_SPEC = [
    {attribute: :date, orderable: true, sort_column: "redemptions.created_at"},
    {attribute: :employee_id, orderable: true, sort_column: "users.employee_id", title: "Employee Id", colvis: :hide},
    {attribute: :first_name, orderable: true, sort_column: "users.first_name", colvis: :hide},
    {attribute: :last_name, orderable: true, sort_column: "users.last_name", colvis: :hide},
    {attribute: :email, orderable: true, sort_column: "users.email", colvis: :hide},
    {attribute: :full_name, orderable: false, export_format: :nodeText},
    {attribute: :catalog, orderable: true, sort_column: "catalogs.currency"},
    {attribute: :reward, orderable: true, sort_column: "rewards.title"},
    {attribute: :reward_type, orderable: true, sort_column: "rewards.reward_type"},
    {attribute: :points, orderable: true, sort_column: "redemptions.points_redeemed"},
    {attribute: :value, orderable: true, sort_column: "redemptions.value_redeemed"},
    {attribute: :reward_label, orderable: true, sort_column: "reward_variants.label"},
    {attribute: :status, orderable: true, sort_column: "redemptions.status"},
    {attribute: :actions, orderable: false, export_format: :nodeText}
  ].freeze

  def all_records
    redemptions = @company.redemptions.joins(reward_variant: { reward: :catalog })
    redemptions = redemptions.where(rewards: {catalog_id: Integer(params[:catalog_id])}) if params[:catalog_id].present?
    redemptions = redemptions.order(sort_columns_and_directions.to_s) if params[:order].present?
    redemptions.includes(:user, reward_variant: { reward: :catalog })
  end

  def default_order
    "[[ 0, \"desc\" ]]"
  end

  def columns_to_search_in
    user_columns = %w[employee_id email first_name last_name display_name].map { |attr| "users.#{attr}" }
    redemption_columns = %w[points_redeemed value_redeemed status].map { |attr| "redemptions.#{attr}" }
    reward_columns = %w[title].map { |attr| "rewards.#{attr}" }
    catalog_columns = %w[currency].map { |attr| "catalogs.#{attr}" }
    reward_variant_columns = %w[label].map { |attr| "reward_variants.#{attr}" }
    user_columns + redemption_columns + reward_columns + catalog_columns + reward_variant_columns
  end

  def filtered_records
    set = self.all_records_filtered_by_date_range(table: :redemptions)
    search_term = params.dig(:search, :value)
    if search_term.present?
      set = filtered_set(set, search_term, columns_to_search_in)
      set = set.references(:users, :reward_variants, :rewards, :catalogs)
    end
    set.paginate(page: page, per_page: per_page)
  end

  def namespace
    'redemptions'
  end

  def serializer
    RewardsRedemptionsSerializer
  end
end
