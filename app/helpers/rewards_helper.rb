module RewardsHelper
  include MoneyRails::ActionViewExtension

  def rewards_dashboard_path(catalog)
    dashboard_company_admin_catalog_rewards_path(catalog_id: catalog.id)
  end

  def rewards_budget_path(catalog)
    company_admin_catalog_rewards_budgets_path(catalog)
  end

  def summary_nav_link(path, name)
    content_tag(:li, class: ('active' if current_page?(path) || show_point_path?(path))) do
      link_to name, path, class: nil
    end
  end

  def rewards_nav_link(path, name, klass: nil, active: current_page?(path))
    content_tag(:li, class: ('active' if active)) do
      link_to name, path, class: klass
    end
  end

  def rewards_nav_dashboard_link(catalog)
    rewards_nav_link(rewards_dashboard_path(catalog), 'Dashboard')
  end

  def rewards_nav_index_link(catalog)
    rewards_nav_link(company_admin_catalog_rewards_path(catalog, network: catalog.company.domain), 'Catalog')
  end

  def edit_company_admin_catalog_link(catalog)
    rewards_nav_link(edit_company_admin_catalog_path(catalog, network: catalog.company.domain), 'Settings')
  end

  def rewards_nav_catalogs_link
    is_active = (page_class.strip == 'company_admin_catalogs')
    rewards_nav_link(company_admin_catalogs_path, 'Catalogs', active: is_active)
  end

  def rewards_nav_redemptions_link(catalog=nil)
    params = catalog.present? ? { catalog_id: catalog.id } : {}
    rewards_nav_link(company_admin_redemptions_path(params), 'Redemptions')
  end

  def rewards_nav_users_link
    is_active = (page_class.strip == 'company_admin_points')
    rewards_nav_link(company_admin_points_path, 'Points', active: is_active)
  end

  def rewards_nav_transactions_link(catalog=nil)
    params = catalog.present? ? { catalog_id: catalog.id } : {}
    rewards_nav_link(company_admin_rewards_transactions_path(params), 'Transactions')
  end

  def rewards_nav_budget_link(catalog)
    rewards_nav_link(rewards_budget_path(catalog), 'Budget')
  end

  def template_reward_link(catalog)
    link_to('Add from template', template_company_admin_catalog_rewards_path(catalog_id: catalog.id),
            class: 'template-reward')
  end

  def provider_reward_link(catalog)
    link_to('Add gift card', provider_company_admin_catalog_rewards_path(catalog_id: catalog.id),
            class: 'provider-reward')
  end

  def custom_reward_link(catalog)
    link_to('Add custom', new_company_admin_catalog_reward_path(catalog_id: catalog.id),
            class: 'company-fulfilled-reward')
  end

  def add_template_reward_button(catalog, reward)
    link_to(I18n.t('dict.add'), new_company_admin_catalog_reward_path(catalog_id: catalog.id, reward: { template_id: reward.id }),
            class: 'button button-full-width button-primary')
  end

  def add_provider_reward_button(provider_reward, catalog)
    # provider rewards should only be added once
    existing_provider_reward = Reward.enabled.for_company(@company).where(provider_reward_id: provider_reward.id).first
    if existing_provider_reward.present?
      link_to(I18n.t('dict.edit'), edit_company_admin_reward_path(existing_provider_reward),
              class: 'button button-full-width button-primary')
    else
      link_to(I18n.t('dict.add'), new_company_admin_catalog_reward_path(catalog_id: catalog.id, reward: {provider_reward_id: provider_reward.id}),
              class: 'button button-full-width button-primary')
    end
  end

  def approve_redemption_button(redemption)
    url = if controller.class == ManagerAdmin::RedemptionsController
            approve_manager_admin_redemption_path(redemption)
          else
            approve_redemption_company_admin_rewards_path(redemption_id: redemption.id)
          end

    link_to(I18n.t('dict.approve'),
            'javascript://',
            class: 'button button-primary approve-button',
            data: {
                endpoint: url,
                redemption_id: redemption.id,
                reward_additional_instructions: redemption.reward.additional_instructions,
                reward_type: redemption.reward.provider_reward? ? 'provider_reward' : 'company_fulfilled_reward',
                request_form_id: SecureRandom.uuid
            }
    )
  end

  def deny_redemption_button(redemption)
    url = if controller.class == ManagerAdmin::RedemptionsController
            deny_manager_admin_redemption_path(redemption)
          else
            deny_redemption_company_admin_rewards_path(redemption_id: redemption.id)
          end

    link_to(I18n.t('dict.deny'), url,
            class: 'button button-secondary deny-button', remote: true, method: :put, data: { redemption_id: redemption.id})
  end

  def redemption_view_details_link(redemption)
    link_to(
      I18n.t('dict.view_details'),
      'javascript://',
      data: {
        redemption: redemption.response_message,
        redeemer: redemption.user.full_name
      },
      class: 'redemption-view-link button button-full-width button-chromeless'
    )
  end

  def redemption_view_additional_instructions_link(redemption)
    return unless redemption.additional_instructions.present?
    link_to(
      I18n.t('dict.view_details'),
      'javascript://',
      data: {
        redemption_additional_instructions:  redemption.additional_instructions
      },
      class: 'redemption-additional-instructions-link button button-full-width button-chromeless'
    )
  end

  def can_publish_reward_template?(company)
    company.recognizeapp?
  end

  def reward_interval_name(value, name)
    Interval::NULL == value ? 'No Limit' : name
  end

  def reward_quantity_interval_name(value, name)
    Interval::NULL == value ? 'Total' : name
  end

  def user_reward_limit(reward)
    if reward.restricted_by_user_limit?
      "#{reward.frequency} #{reward.interval.name}"
    else
      reward.interval.name
    end
  end

  # def company_reward_limit(reward)
  #   if reward.restricted_by_quantity?
  #     "#{reward.quantity} #{reward.quantity_interval.name}"
  #   else
  #     reward.interval.name
  #   end
  # end

  def reward_points_label(reward)
    reward.variants.enabled.map{|v| v.points }.join(',<br>').html_safe
  end

  def reward_value_label(reward)
    reward.variants.enabled.map{|v| humanized_money_with_symbol(Money.from_amount(v.face_value, reward.catalog.currency))}.join(',<br>').html_safe
  end

  def animate_rewards_admin_header_classes(catalog)
    if current_page?(rewards_dashboard_path(catalog))
      'animate-2 animate-hidden animate'
    end
  end

  # def get_redeemed_points(redemptions)
  #   redemptions.approved.sum(:points_redeemed)
  # end

  def top_stats(redemptions)
    company_rewards = {}
    giftcard_rewards = {}

    redemptions.each do |r|
      rewards = r.reward.provider_reward? ? giftcard_rewards : company_rewards
      rewards[r.reward.id] = if rewards[r.reward.id].present?
                               rewards[r.reward.id] + 1
                             else
                               1
                             end
    end

    giftcard_rewards = Hash[giftcard_rewards.sort_by{|k, v| v}.reverse].to_a
    company_rewards = Hash[company_rewards.sort_by{|k, v| v}.reverse].to_a

    {
      company_rewards: company_rewards[0..15],
      giftcard_rewards: giftcard_rewards[0..15]
    }
  end

  def catalog_based_redemption_points_stats(company, redemptions)
    company_catalog_ids = company.catalogs.pluck(:id)
    catalog_by_company_rewards_redemption_points_map = Hash[company_catalog_ids.map { |catalog_id| [catalog_id, 0] }]
    catalog_by_giftcard_rewards_redemption_points_map = catalog_by_company_rewards_redemption_points_map.dup

    redemptions.each do |redemption|
      relevant_map = if redemption.reward.provider_reward?
                       catalog_by_giftcard_rewards_redemption_points_map
                     else
                       catalog_by_company_rewards_redemption_points_map
                     end
      relevant_map[redemption.reward.catalog.id] += redemption.points_redeemed
    end

    catalog_by_giftcard_rewards_redemption_points_map = Hash[catalog_by_giftcard_rewards_redemption_points_map.sort_by { |_, v| v }.reverse].to_a
    catalog_by_company_rewards_redemption_points_map = Hash[catalog_by_company_rewards_redemption_points_map.sort_by { |_, v| v }.reverse].to_a

    {
      catalog_by_company_rewards_redemption_points_map: catalog_by_company_rewards_redemption_points_map,
      catalog_by_giftcard_rewards_redemption_points_map: catalog_by_giftcard_rewards_redemption_points_map
    }
  end

  def show_currency?(company)
    company.catalogs.any?
  end

  # def reward_image_tag(reward)
  #   image_tag(reward.image_url)
  # end

  def redemptions_info(user)
    points = user.redemptions.approved_or_pending.by_catalog(@catalog).sum(:points_redeemed)
    redemption_count = user.redemptions.approved.by_catalog(@catalog).size
    redeemed_money = humanized_money_with_symbol(Money.from_amount(points / @reward_calculator.points_to_currency_ratio, @catalog.currency))
    redeemed_points = t('dict.pts', points: number_with_delimiter(points))

    [redemption_count, redeemed_money, redeemed_points]
  end

  def provider_reward_of_reward_is_disabled?(reward)
    reward.persisted? && reward.provider_reward? && !reward.provider_reward.active?
  end

  def show_point_path?(path)
    current_page?(path.gsub('summary', request.fullpath.split('/').last))
  end
end
