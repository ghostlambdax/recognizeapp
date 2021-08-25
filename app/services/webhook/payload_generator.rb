# frozen_string_literal: true

module Webhook
  class PayloadGenerator
    include ActionView::Helpers::JavaScriptHelper

    attr_reader :object, :event_name, :payload_template, :opts

    # Add generic attributes here to exclude them from the payload, eg. %i[type api_url web_url]
    # works recursively for nested attributes too
    EXCLUDED_ENTITY_ATTRIBUTES = []

    # Note: event_name is only needed when payload_template is empty and vice-verse
    def self.generate(object, event_name, payload_template, opts = {})
      new(object, event_name, payload_template, opts).generate
    end

    def initialize(object, event_name, payload_template, opts = {})
      @object = object
      @event_name = event_name
      @payload_template = payload_template
      @opts = opts
    end

    def generate
      if payload_template.present?
        generate_payload_from_template
      elsif payload_template.nil?
        default_payload
      else # empty string
        '' # empty payload
      end
    end

    def default_payload
      object_name = object.class.name.demodulize.underscore
      serializable_object = serializable_entity_hash
      payload = {
        event_name: event_name,
        object_name.to_sym => serializable_object
      }
      payload = payload.deep_transform_values{|v| v.kind_of?(String) ? escape_javascript(v) : v } if escape_values?
      payload.to_json
    end

    def escape_values?
      !!opts[:escape_values]
    end

    def generate_payload_from_template
      template = Liquid::Template.parse(payload_template)
      attributes_hash = serializable_entity_hash.stringify_keys
      attributes_hash = attributes_hash.deep_transform_values{|v| v.kind_of?(String) ? escape_javascript(v) : v  } if escape_values?
      template.render(attributes_hash)
    rescue => e
      log_render_error(e)
      ''
    end

    def serializable_entity_hash
      entity_class = get_object_entity
      entity_instance = entity_class.new(object)
      entity_hash = entity_instance.serializable_hash.tap do |hash|
        hash.default = '' # ignore missing keys during interpolation
        remove_excluded_attributes!(hash) if EXCLUDED_ENTITY_ATTRIBUTES.present?
      end

      # workaround to allow access to entity attributes (including nested ones) in Liquid templates
      # https://github.com/ruby-grape/grape-entity/issues/351
      JSON.parse(JSON.dump(entity_hash))
    end

    # Removes excluded attributes from a hash (including nested hashes), mutating the original object
    # Note: Recursive function
    def remove_excluded_attributes!(hash)
      hash.each do |attr, val|
        if attr.in?(EXCLUDED_ENTITY_ATTRIBUTES)
          hash.delete(attr)
        elsif val.is_a? Array
          val.each {|v| remove_excluded_attributes!(v) if v.is_a?(Hash) }
        elsif val.is_a? Hash
          remove_excluded_attributes!(val)
        end
      end
    end

    def get_object_entity
      if object.respond_to?(:webhook_entity)
        # allow specifying explicitly
        # for possible future usage - this is not used currently in the first pass
        object.webhook_entity
      else # fallback to API entity
        default_classname = "Api::V2::Endpoints::#{object.class.name.pluralize}::Entity"
        # note: this check requires the class to be autoloaded
        default_classname.constantize if Object.const_defined?(default_classname)
      end
    end

    private

    def log_render_error(e)
      Rails.logger.error("Webhook::Endpoint: Error encountered when rendering template string (#{e})")
      Rails.logger.error(%(template string: "#{payload_template}"))
      Rails.logger.error("object info: class - #{object&.class}, id - #{object&.id}")
    end
  end
end
