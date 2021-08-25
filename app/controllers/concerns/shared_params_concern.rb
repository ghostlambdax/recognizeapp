
# Share whitelisted parameters between controllers

module SharedParamsConcern
  extend ActiveSupport::Concern

  private

  def badge_params
    params
      .fetch(:badge, {})
      .permit(
        :description, :long_description, :name, :short_name, :long_name, :company, :image, :image_cache, :restricted,
        :achievement_frequency, :achievement_interval_id, :is_instant, :is_achievement, :is_nomination, :show_in_badge_list,
        :disabled_at, :points,
        :sending_frequency, :sending_interval_id, :sending_limit_scope_id,
        :anniversary_template_id, :anniversary_message, :nomination_award_limit_interval_id,
        :is_quick_nomination, :allow_self_nomination,
        :is_enabled, :sort_order
      )
  end
end
