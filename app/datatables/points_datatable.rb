require 'will_paginate/array'
class PointsDatatable < Litatable
  include DateTimeHelper

  COLUMN_SPEC = [
    { attribute: :user, orderable: true, sort_column: "users.email", export_format: :nodeText },
    { attribute: :redeemable_points, orderable: true, sort_column: "users.redeemable_points", title: I18n.t("dict.redeemable_points") },
    { attribute: :redeemed_points, orderable: true, sort_column: "users.redeemed_points", title: I18n.t("dict.redeemed_points") },
    { attribute: :status, orderable: true, sort_column: "users.status", title: I18n.t("dict.status") },
    { attribute: :show_points, orderable: false, title: I18n.t("dict.show_points"), export: false  }
  ].freeze

  COLUMN_TABLE_MAP = {
    "user" => "users.email",
    "redeemable_points" => "redeemable_points",
    "redeemed_points" => "redeemed_points",
    "status" => "status",
    "show_points" => "show_points"
  }

  COLUMN_ATTRIBUTES = {
    0 => { export_format: :nodeText },
    4 => { orderable: false, export_format: :removeLink }
  }

  def all_records
    company.users.order("#{sort_columns_and_directions}") if params[:order].present?
  end

  def columns
    columns = {
      0 => "user",
      1 => "redeemable_points",
      2 => "redeemed_points",
      3 => "status",
      4 => "show_points"
    }
    return columns
  end

  def column_table_map
    COLUMN_TABLE_MAP
  end

  def default_order
    "[[ 0, \"asc\" ]]"
  end

  def filtered_records
    set = self.all_records

    if params[:search].present? && params[:search][:value].present?
      tokens = params[:search][:value].split(" ")
      conditions = []

      tokens.each do |token|
        conditions = ["users.first_name like :search"]
        conditions << "users.last_name like :search"
        conditions << "users.email like :search"
        conditions << "users.status like :search"
        conditions << "users.redeemed_points like :search"
        conditions << "users.redeemable_points like :search"
        set = set.where(conditions.join(" OR "), search: "%#{token}%")
      end
    else
      # since set returns an object of User::ActiveRecord_Associations_CollectionProxy
      # we can make use of the `not_disabled` scope directly
      set = set.not_disabled
    end

    set.paginate(page: page, per_page: per_page)
  end

  def namespace
    'points'
  end

  def serializer
    RewardsUserSerializer
  end

  def include_all_option_in_length_menu
    false
  end

  def server_side_export
    true
  end

  def column_attributes
    @column_attributes ||= begin
      ca = {}
      column_spec.each_with_index{|col, i| ca[i] ||= col}
      ca
    end
  end

  def column_spec
    COLUMN_SPEC
  end
end
