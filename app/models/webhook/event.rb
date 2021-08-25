# frozen_string_literal: true

module Webhook
  class Event < ApplicationRecord
    # list of possible events - used for validation
    # new events to be added as needed
    # to add support for a new event,
    #   - broadcast it from relevant model callback,
    #   - add listener in app/listeners/webhook/listener.rb that triggers delivery
    #   - add model class string to webhook listener scope in config/initializers/wisper.rb
    #   - add relevant spec in spec/models/webhook/integration_spec.rb to verify
    #
    # EVENT_OBJECT_MAP is a map of the association on a company that is used to
    #                  determine the objects for a particular event. The keys
    #                  are the event types associated to that class of that association.
    # IMPORTANT: if a new class is added, remember to implement #summary_label for the object
    EVENT_OBJECT_MAP = {
      recognitions: %w[recognition_pending recognition_approved],
      redemptions: %w[redemption_pending redemption_approved]
    }.freeze

    # EVENT_OBJECT_LOOKUP_MAP is an inverted association, so we can quickly lookup the association
    #                         by indexing into the event. 
    #                         eg. EVENT_OBJECT_LOOKUP_MAP[:recognition_pending] == "recognitions"
    EVENT_OBJECT_LOOKUP_MAP = Webhook::Event::EVENT_OBJECT_MAP.each_with_object({}){|(key,values), hash|  values.each{|v| hash[v.to_sym] = key.to_sym}}
    EVENT_TYPES = EVENT_OBJECT_MAP.values.flatten.freeze

    RECENT_LIMIT = 100

    belongs_to :endpoint, class_name: 'Webhook::Endpoint'
    belongs_to :company

    validates :company, presence: true
    validates :name, presence: true, inclusion: { in: EVENT_TYPES }
    validates_presence_of :request_method, :request_url

    def self.table_name_prefix
      'webhook_'
    end

    def self.recent_limit
      RECENT_LIMIT
    end

    def self.create_from_endpoint!(endpoint, additional_attrs = {})
      endpoint.events.create!(company: endpoint.company,
                              name: endpoint.subscribed_event,
                              request_url: endpoint.target_url,
                              request_method: endpoint.request_method,
                              **additional_attrs)
    end

    def failed?
      # matches 4xx & 5xx
      /^([45])\d{2}$/.match?(response_status_code.to_s.strip)
    end
  end
end
