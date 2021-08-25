# frozen_string_literal: true

require 'will_paginate/array'

# Caution! CompanyPointActivitiesDatatable inherits from UserPointActivitiesDatatable.
class UserPointActivitiesDatatable < Litatable
  include DateTimeHelper

  COLUMN_SPEC = [
    { attribute: :date, orderable: true, sort_column: "point_activities.created_at", title: proc { I18n.t("dict.date") } },
    { attribute: :activity, orderable: false, title: proc { I18n.t("dict.activity") } },
    { attribute: :amount, orderable: true, sort_column: "point_activities.amount", title: proc { I18n.t("dict.amount") } },
    { attribute: :description, orderable: false, title: proc { I18n.t("dict.description") } },
    { attribute: :is_redeemable, ordertable: true, sort_column: "point_activities.is_redeemable", title: proc { I18n.t("dict.is_redeemable") } }
  ].freeze

  def initialize(view, user)
    @view = view
    @user = user
    @company = user.company
    super(@view, @company)
  end

  def all_records
    activities = @user.point_activities.includes(recognition: :badge).references(recognition: :badge)
    activities = activities.order("#{sort_columns_and_directions}") if params[:order].present?
    return activities
  end

  def default_order
    "[[ 0, \"desc\" ]]"
  end

  def filtered_records
    set = self.all_records_filtered_by_date_range(table: :point_activities)
    set = set.where(point_activities: {is_redeemable: params[:is_redeemable]}) if params[:is_redeemable].present?

    search_term = params.dig(:search, :value)
    return paginated_set(set) unless search_term.present?

    # this keeps quoted strings in search together
    # eg ["word1", "word2", "other search phrase"]
    search_terms = search_term.scan(/("[^"]+"|\w+)\s*/).flatten
    search_terms.each do |term|
      tokens = translate_token(term.delete('"'))
      set = extended_text_search(set, term, tokens) # use AND between search terms
    end

    paginated_set(set)
  end

  def filters
    choices = [
      [I18n.t("dict.all"), nil],
      [I18n.t("dict.redeemable"), 1],
      [I18n.t("dict.non_redeemable"), 0]
    ]
    [SelectFilter.new(:is_redeemable, nil, choices)]
  end

  def namespace
    'user_point_activities'
  end

  def serializer
    PointActivitySerializer
  end

  def colvis_options
    {}
  end

  def serialize_to_hash
    super.merge({user_id: @user&.id})
  end

  def server_side_export
    enabled_paths = ["company_admin/points"]
    enabled_paths.include?(view.controller_path)
  end

  private

  def columns_to_search_in
    %w[
      point_activities.amount point_activities.activity_type
      recognitions.slug
      badges.short_name
    ]
  end

  # see if a search term matches activity labels and translate it to relevant activity types (i.e. db strings)
  def translate_token(term)
    inverted_map = serializer.new(nil).inverted_activity_label_map
    inverted_map.select{|k,_v| k.match(/#{Regexp.escape(term)}/i)}.values
  end

  def extended_text_search(set, search_term, activity_type_tokens)
    conditions = []
    ar_connection = ActiveRecord::Base.connection

    # first search in all the whitelisted columns for the actual term
    columns_to_search_in.each do |column|
      conditions << %(#{column} like #{ar_connection.quote("%#{search_term}%")})
    end

    # then search in `activity_type` column for the matching tokens
    activity_type_tokens.each do |token|
      conditions << %(point_activities.activity_type like #{ar_connection.quote(token)})
    end

    set.where(conditions.join(" OR "))
  end
end
