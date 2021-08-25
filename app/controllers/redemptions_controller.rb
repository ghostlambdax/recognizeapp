class RedemptionsController < ApplicationController
  filter_access_to :all, attribute_check: true, load_method: :current_user
  show_upgrade_banner only: [:index]
  include RedemptionsHelper

  before_action :ensure_catalog, only: :index

  def index
    @current_catalog = @redeemable_catalogs.detect { |catalog| catalog.id.to_s == params[:catalog_id] }

    gon.push(
        redeem: I18n.t('rewards.redeem'),
        cancel: I18n.t('swal.cancel')
    )

    @rewards = begin
                 return [] unless @current_catalog.present?
                 company_money_balance = Rewards::MoneyDepositer.new(company: @company, catalog: @current_catalog).balance
                 rewards = current_user.redeemable_rewards(catalog_ids: @current_catalog.id)
                 rewards = rewards.select do |reward|
                   # only show rewards in catalog that company has enough money to provide for
                   if reward.provider_reward?
                     reward.lowest_variant.present? ? reward.lowest_variant.face_value < company_money_balance : false
                   else
                     true
                   end
      end
      rewards.sort_by { |reward| reward.title.downcase } # Do a case insensitive sort; similar to AR `order`.
    end
  end

  def create
    @reward = @company.rewards.find(params[:redemption][:reward_id])
    @variant = @reward.variants.find(params[:redemption][:variant_id])
    @redemption = Redemption.redeem(current_user, @variant)
    respond_with @redemption, onsuccess: {method: "fireEvent", params: create_action_response_params}
  end

  private

  def create_action_response_params
    price = view_context.humanized_money_with_symbol(Money.from_amount(@redemption.value_redeemed, @reward.catalog.currency)).no_zeros

    {
      name: "updatedRewards",
      redeemable_points: current_user.redeemable_points,
      remaining_quantity: @reward.quantity_remaining,
      content: {
        title: reward_title(price),
        description: reward_description
      },
      redemption: {
        price: price,
        points: @redemption.points_redeemed,
        image_url: @reward.image_url
      }
    }
  end

  def reward_description
    if @redemption.auto_approved?
      I18n.t('rewards.post_redeem.auto_approved.description_html')
    else
      I18n.t('rewards.post_redeem.description_html',
        full_name: @reward.manager_with_default.full_name,
        email: @reward.manager_with_default.email)
    end
  end

  def reward_title(price)
    if @reward.provider_reward?
      translation_key = if @redemption.auto_approved?
        'rewards.post_redeem.auto_approved.title_provider'
      else
        'rewards.post_redeem.title_provider'
      end
      I18n.t(translation_key, reward_title: @reward.title, price: price)
    else
      I18n.t('rewards.post_redeem.title_company_fulfilled', reward_title: @reward.title)
    end
  end

  def ensure_catalog
    @redeemable_catalogs = current_user.redeemable_catalogs.sort_by(&:currency)

    if params[:catalog_id].blank? && @redeemable_catalogs.present?
      #
      # Note: In an ideal scenario, the Rewards link (pointing to Redemption#index) action would be scoped to a redeemable
      # catalog for a user. However, the computation logic of redeemable catalogs for a user is kinda expensive (makes too
      # many database calls with the current roles and permissions architecture). Since, the top bar nav can be rendered
      # for every page visits, rather than hard-wiring the catalog in the link, we instead do necessary computations and
      # redirect with appropriate catalog_id only when user tries to visit Redemption#index to make the overall UX
      # performant.
      #
      redirect_to redemptions_path(network: @company.domain, catalog_id: @redeemable_catalogs.first.id) and return
    end
  end
end
