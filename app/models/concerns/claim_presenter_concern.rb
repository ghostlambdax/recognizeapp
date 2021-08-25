module ClaimPresenterConcern
  def claim_presenter
    ClaimPresenter.new(self)
  end

  class ClaimPresenter
    attr_reader :redemption

    def initialize(redemption)
      @redemption = redemption
    end

    # https://developers.tangocard.com/docs/implementation-notes#section-handling-reward-types
    def claim_infos
      (reward_details["credentialList"] || []).map do |cred|
        claim_type = cred['type'].presence || "text"
        send("#{claim_type}_claim", cred['label'], cred['value'])
      end
    end

    def instructions
      reward_details["redemptionInstructions"]
    end

    protected

    def text_claim(label, value)
      "<strong>#{label}</strong>: #{value}"
    end

    def url_claim(label, value)
      "<strong>#{label}</strong>: <a target='_blank' href='#{value}'>#{value}</a>"
    end

    def barcode_claim(label, value)
      "<strong>#{label}</strong>:<br><img style='max-width: 100%;' src='#{value}' alt='Reward barcode'>"
    end

    # TODO (maybe): display date in user's timezone? (previously the JS formatter used to do this in user profile)
    # Maybe PR #1515 for User/Company Timezone support could help (PR still open at the time of writing)
    def date_claim(label, value)
      text_claim(label, value)
    end

    def reward_details
      raw_response = redemption.response_message
      @_reward_details ||= raw_response ? JSON.parse(raw_response)["reward"] : {}
    end
  end
end