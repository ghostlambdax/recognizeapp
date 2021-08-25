module TangoCard
  class Client
    DEFAULT_ENDPOINT = 'https://sandbox.tangocard.com/raas/v2/'
    @endpoint = Recognize::Application.config.rCreds.dig("tangocard", "endpoint") || DEFAULT_ENDPOINT
    @username = Recognize::Application.config.rCreds.dig("tangocard", "username") || ''
    @password = Recognize::Application.config.rCreds.dig("tangocard", "password") || ''

    def self.recognize_balance
      get('/accounts').first["currentBalance"]
    end

    def self.get_rewards
      response = HTTParty::get(@endpoint + '/catalogs', auth_params)
      response["brands"].map {|b| Brand.new(b)}
    end

    def self.redeem(redemption)
      amount = redemption.value_redeemed
      variant = redemption.reward_variant
      provider_reward_variant = variant.provider_reward_variant
      raise "Could not find provider reward variant for redemption(#{redemption.id})" unless provider_reward_variant.present?

      reward_sender = redemption.reward.manager_with_default

      params = {
        accountIdentifier: "recognize",
        amount: amount,
        customerIdentifier: "recognize",
        sendEmail: false,
        recipient: {
          email: redemption.user.email,
          firstName: redemption.user.first_name,
          lastName: redemption.user.last_name
        },
        sender: {
          email: reward_sender.email,
          firstName: reward_sender.first_name,
          lastName: reward_sender.last_name
        },
        utid: provider_reward_variant.provider_key,
        externalRefID: "#{Rails.application.config.host}-#{redemption.id}"
      }

      Rails.logger.debug "TANGO: Issuing order to Tango: #{params.to_json}"

      response = HTTParty::post(@endpoint + '/orders', {body: params.to_json, headers: { 'Content-Type' => 'application/json' }}.merge(auth_params))
      Rails.logger.debug "TANGO: Got response from Tango: #{response}"
      amount_charged = {
        value:  response.dig("amountCharged", "value"),
        currency_code:  response.dig("amountCharged", "currencyCode"),
        exchange_rate: response.dig("amountCharged", "exchangeRate"),
        total: response.dig("amountCharged", "total")
      }
      {success: response.code == 201, response: response.to_json, amount_charged: amount_charged}
    end

    def self.get(path)
      response = HTTParty::get(@endpoint + path, auth_params)
      return response
    end

    private

    def self.auth_params
      {:basic_auth => {:username => @username, :password => @password}}
    end
  end
end
