class CompanyAdmin::RewardsController < CompanyAdmin::BaseController

  layout "rewards_admin"

  before_action :show_sample_if_unpaid, except: [:show_sample]
  before_action :set_catalog, only: [:index, :new, :create, :template, :provider, :dashboard]

  # GET /:network/company/catalogs/:catalog_id/rewards/dashboard
  def dashboard
    @reward_calculator = Rewards::RewardPointCalculator.new(@company, @catalog)
    @top_redeeming_employees = @company.users
                                 .where("users.redeemed_points > 0")
                                 .sort_by {|a| -a.redemptions.approved.by_catalog(@catalog).size}[0..4]
    @company_money = Rewards::MoneyDepositer.new(company: @company, catalog: @catalog)

    @redemptions = @company.redemptions.by_catalog(@catalog)
    @redemptions_for_chart = @redemptions.not_denied.includes(:reward)
  end

  # GET /:network/company/catalogs/:catalog_id/rewards
  def index
    @rewards_count = @company.rewards.size
    @datatable = RewardsDatatable.new(view_context, @company, @catalog)
    respond_with(@datatable)
  end

  # GET /:network/company/catalogs/:catalog_id/rewards/new
  def new
    attributes = template_reward_attributes if params[:reward].present?
    attributes = provider_reward_attributes if attributes.blank?
    attributes = {} if attributes.blank?
    attributes = attributes.merge({catalog_id: @catalog.id})
    @reward = @company.rewards.build(attributes)

    if @reward.discrete_provider_reward?
      @reward.initialize_discrete_variants
    else
      @reward.variants.build
    end
  end

  # POST /:network/company/catalogs/:catalog_id/rewards
  def create
    rp = reward_params
    rp.delete("template_id")
    @reward = @company.rewards.build(rp)
    @reward.catalog_id = @catalog.id
    if @reward.save
      if reward_params[:image].blank? && template_reward.present? && template_reward_image.present?
        # this may a bit overkill, but it works.
        @reward.image = template_reward.image
        @reward.save
        @reward.image.recreate_versions!
      end
      flash[:notice] = "Reward successfully created."
      respond_with(@reward, location: company_admin_catalog_rewards_path(@reward.catalog_id))
    else
      respond_with(@reward)
    end
  rescue StandardError, ImageAttachmentUploader::ImproperFileFormat => e
    @reward ||= Reward.new
    @reward.errors.add(:image, e.message)
    respond_with(@reward)
  end

  def edit
    @reward = @company.rewards.find(params[:id])
    if @reward.discrete_provider_reward?
      @reward.initialize_discrete_variants
    end
  end

  def update
    @reward = @company.rewards.find(params[:id])

    rp = reward_params
    rp.delete("template_id")
    if @reward.update(rp)
      flash[:notice] = "Reward successfully updated."
      respond_with(@reward, location:  company_admin_catalog_rewards_path(@reward.catalog_id))
    else
      respond_with(@reward)
    end
  rescue StandardError, ImageAttachmentUploader::ImproperFileFormat => e
    @reward.errors.add(:image, e.message)
    respond_with(@reward)
  end

  def destroy
    @reward = @company.rewards.find(params[:id])
    @reward.toggle :enabled
    unless @reward.save
      response_hash = { errors: @reward.errors.full_messages, errorTitle: 'Not Activating' }
      return render json: response_hash, status: :unprocessable_entity
    end
  end

  # GET /:network/company/catalogs/:catalog_id/rewards/template
  def template
    @rewards = Rewards::RewardService.template_rewards
  end

  # GET /:network/company/catalogs/:catalog_id/provider
  def provider
    @company_money = Rewards::MoneyDepositer.new(company: @company, catalog: @catalog)
    @provider_rewards = Rewards::RewardService.provider_rewards(@catalog)
  end

  def show_sample
    # noop, just render template
  end


  def approve_redemption
    @redemption = @company.redemptions.find(params[:redemption_id])
    @redemption.approve(approver: current_user, additional_instructions: params[:redemption_additional_instructions], request_form_id: params[:request_form_id])
    status = @redemption.errors.size > 0 ? 422 : 200
    render action: 'approve_redemption', status: status
  end

  def deny_redemption
    @redemption = @company.redemptions.find(params[:redemption_id])
    @redemption.deny(denier: current_user)
    status = @redemption.errors.size > 0 ? 422 : 200
    render action: 'deny_redemption', status: status
  end

  private

  def show_sample_if_unpaid
    unless @company.allow_admin_dashboard?
      redirect_to(show_sample_company_admin_rewards_path)
    end
  end

  def reward_params
    params.require(:reward).permit(:title, :description, :additional_instructions, :value, :frequency,
      :template_id,
      :interval_id, :quantity, :quantity_interval_id, :provider_reward_id, :reward_type,
      :manager_id, :image, :published, :enabled, variants_attributes: [:id, :provider_reward_variant_id, :face_value, :quantity, :label, :is_enabled])
  end

  def template_reward_attributes
    return {} if template_reward.nil?
    { title: template_reward.title,
      description: template_reward.description,
      image: template_reward.image
    }

  end

  def provider_reward_attributes
    return {} if provider_reward.nil?
    { title: provider_reward.name,
      description: provider_reward.description,
      provider_reward: provider_reward,
      reward_type: provider_reward.reward_type
    }

  end

  def template_reward
    @template_reward ||= Rewards::RewardService.find_template_reward(reward_params[:template_id])
  end

  def provider_reward
    Rewards::ProviderReward.find(reward_params[:provider_reward_id]) rescue nil
  end

  def template_reward_image
    @template_reward_image ||= template_reward.try(:image).try(:url)
  end

  def set_catalog
    @catalog = @company.catalogs.find_by(id: params[:catalog_id])
    redirect_to company_admin_catalogs_path  unless @catalog
  end
end
