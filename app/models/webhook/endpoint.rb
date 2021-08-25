# frozen_string_literal: true

module Webhook
  class Endpoint < ApplicationRecord
    # POST is the default in db
    ALLOWED_REQUEST_METHODS = %w[POST GET].freeze
    TOKEN_MASK_STARS = "****************"
    AUTO_DISABLE_FAILURE_THRESHOLD = 5

    belongs_to :owner, class_name: 'User'
    belongs_to :company

    has_many :events, class_name: 'Webhook::Event', dependent: :destroy

    validates :target_url, presence: true
    validates :target_url, format: {with: URI.regexp(%w[http https]), message: ->(object,data){_("^Target url must a properly formatted url.")}}, allow_blank: true
    validates :request_method, presence: true, inclusion: { in: ALLOWED_REQUEST_METHODS } # default is POST
    validates :company, presence: true
    validates :owner, presence: true
    validates :subscribed_event, presence: true, inclusion: { in: Webhook::Event::EVENT_TYPES }

    scope :for_event, ->(event_name) { where(subscribed_event: event_name) }
    scope :not_disabled, -> { where(is_active: true) }

    encrypts :authentication_token

    def self.table_name_prefix
      'webhook_'
    end

    def self.token_mask_stars
      TOKEN_MASK_STARS
    end
    
    def self.allowed_request_methods
      ALLOWED_REQUEST_METHODS
    end

    def self.allowed_event_types
      Webhook::Event::EVENT_TYPES
    end

    def recent_objects(limit: 100)
      association = Webhook::Event::EVENT_OBJECT_LOOKUP_MAP[subscribed_event.to_sym]
      # eg, company.recognitions.last(limit) for 'recognition_approved'
      #     gets the last set of recognitions that are appropriate for the 'recognition_approved' event
      company.send(association).reorder('created_at desc').first(limit)
    end

    def deliver(event_name, object)
      gid = object.to_global_id.to_s
      WebhookDeliveryJob.perform_later(id, event_name, gid)
    end

    def eligible_for_auto_disable?
      threshold = AUTO_DISABLE_FAILURE_THRESHOLD
      events.last(threshold).count(&:failed?) == threshold
    end
  end
end
