require 'will_paginate/array'
class RewardsDatatable < DatatablesBase

  attr_reader :catalog
  def initialize(view, company, catalog)
    @catalog = catalog
    super(view, company)
  end

  def all_records
    rewards = catalog.rewards.includes(:manager).references(:user)
    rewards = rewards.order("#{sort_columns_and_directions}") if params[:order].present?
    return rewards
  end

  def column_table_map
    @column_table_map ||= {
        "id" => "rewards.id",
        "title" => "rewards.title",
        "image" => "image",
        "value" => "value",
        "points" => "points",
        "user_limit" => "rewards.frequency",
        "quantity_available" => "quantity",
        "total_redeemed" => "total_redeemed",
        "manager" => "users.first_name",
        "reward_type" => "rewards.reward_type",
        "published" => "published",
        "status" => "rewards.enabled",
        "edit" => "edit",
        "actions" => "actions"
      }.tap do |ct_map|
        ct_map.delete("published") unless @company.recognizeapp?
      end
  end

  def columns
    column_name_array = column_table_map.keys
    column_index_array = column_name_array.size.times.to_a
    # Merge same-index elements of two arrays; Eg: [0, 1].zip(["id", "name"]) => [[0, "id"], [1, "name"]]
    column_index_and_name_array = column_index_array.zip(column_name_array)
    column_index_and_name_array.to_h
  end

  def namespace
    'rewards'
  end

  def filtered_records
    rewards = all_records
    search_term = params.dig(:search, :value)
    if search_term.present?
      columns_to_search_in = %w[title users.last_name users.first_name]
      rewards = filtered_set(rewards, search_term, columns_to_search_in)
    end
    rewards.paginate(page: page, per_page: per_page)
  end

  def serializer
    RewardsSerializer
  end

  # overrides parent method to return dynamic attributes
  # to account for the optional column `published`, which is only present in recognizeapp.com
  def column_attributes
    @column_attributes ||= begin
      unorderable_columns = %w[image value points quantity_available total_redeemed edit actions]
      columns = column_table_map.keys

      unorderable_columns.reduce({}) do |attrs, key|
        attrs[ columns.index(key) ] = { orderable: false }; attrs
      end
    end
  end

end
