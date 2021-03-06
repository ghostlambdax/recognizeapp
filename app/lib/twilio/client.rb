module Twilio
  class Client
    attr_reader :sid, :token, :client, :number

    def initialize(sid, token, number)
      @sid = sid
      @token = token
      @client = Twilio::REST::Client.new(sid, token)
      @number = number
    end

    def send_sms(to, msg)
      client.api.account.messages.create(
        from: number,
        to: format_number(to),
        body: msg
      )
    end

    def lookup
      @lookup ||= Twilio::REST::Lookups.new(client)
    end

    private
    def format_number(number)
      number
    end
  end
end
