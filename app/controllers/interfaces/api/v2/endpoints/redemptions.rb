class Api::V2::Endpoints::Redemptions < Api::V2::Base
  include Api::V2::Defaults

  class Entity < Api::V2::Entities::Base
    include ::UsersHelper
    include ::RedemptionsHelper
    include MoneyRails::ActionViewExtension


    root 'redemptions', 'redemption'

    expose :redemption_title
    expose :redemption_amount
    expose :redemption_details_html
    expose :redemption_status
    expose :redemption_extra_info
    expose :additional_instructions
    expose :created_at
    expose :reward_manager
    expose :employee_id
    expose :user, using: Api::V2::Endpoints::Users::Entity, documentation: { type: Api::V2::Endpoints::Users::Entity, desc: 'Redeemer of the redemption'}
    expose :reward, using: Api::V2::Endpoints::Rewards::Entity, documentation: { type: Api::V2::Endpoints::Rewards::Entity, desc: 'Reward that was redeemed'}

    def redemption_title
      format_redemption_title(object)
    end

    def redemption_details_html
      redemption_instructions = nil
      if object.reward.provider_reward?
        redemption_instructions = object.claim_presenter.instructions
      else
        # this code is included in both web app and the API for mobile app, should be included in claim_presenter
        redemption_instructions = I18n.t('rewards.company_managed_redemption_instructions') if object.approved?
      end
      return redemption_instructions
    end

    def redemption_status
      redemption_status_text(object.status)
    end

    def redemption_extra_info
      object.claim_presenter.claim_infos
      # format_redemption_extrainfo(object)
    end

    def reward_manager
      manager = object.reward.manager_with_default

      response = {
        avatar_url: manager.avatar.url,
        full_name: User.find(manager.id).full_name,
        job_title: manager[:job_title],
        phone: manager[:phone],
        email: manager[:email]
      }

      return response
    end

    def employee_id
      object.user&.employee_id
    end

    def redemption_amount
      object.amount
    end
  end


  mount Api::V2::Endpoints::Redemptions::Index
  mount Api::V2::Endpoints::Redemptions::Show
  mount Api::V2::Endpoints::Redemptions::Create

end
