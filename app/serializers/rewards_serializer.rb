class RewardsSerializer < BaseDatatableSerializer
  include RewardsHelper
  include ActionView::Helpers::NumberHelper

  attributes :id, :image, :title, :value, :points, :user_limit, :quantity_available, :total_redeemed, :reward_type, :manager, :published, :status, :edit, :actions



  def value
    reward_value_label(object)
  end

  def image
    context.image_tag(object.image_url)
  end

  def points
    reward_points_label(object)
  end

  def user_limit
    user_reward_limit(object)
  end

  def quantity_available
    return unless object.quantity.present?
    I18n.t("rewards.quantity_available", remaining: object.quantity_remaining, total: object.quantity)
  end

  def total_redeemed
    object.existing_company_redemptions_count_in_interval
  end

  def manager
    object.manager.try(:label)
  end

  def published
    object.published? ? I18n.t("dict.true") : I18n.t("dict.false")
  end

  def status
    object.enabled? ? I18n.t("dict.active") : I18n.t("dict.disabled")
  end

  def edit
    return if provider_reward_of_reward_is_disabled?(object)

    context.link_to(
      I18n.t("dict.edit"),
      edit_company_admin_reward_path(object),
      class: "button button-chromeless"
    )
  end

  def actions
    content_div if object.enabled || object.can_be_enabled?
  end

  private

  def content_div
    context.link_to(
        actions_label,
        company_admin_reward_path(object),
        method: :delete,
        remote: true,
        data: { confirm: I18n.t("forms.are_you_sure"), rewardId: object.id },
        class: "reward-status-toggle button button-chromeless danger"
    )
  end

  def actions_label
    object.enabled? ? I18n.t("dict.disable") : I18n.t("dict.activate")
  end
end