# frozen_string_literal: true

class WebhookDeliveryJob < ApplicationJob
  queue_as :priority

  def perform(endpoint_id, event_name, gid)
    @endpoint = Webhook::Endpoint.find_by(id: endpoint_id)
    return unless @endpoint

    runner = Runner.new(@endpoint, event_name, gid)
    runner.perform!
  end

  def named_job_arguments(job_arguments, hash)
    endpoint_id = job_arguments[0]
    endpoint = Webhook::Endpoint.find(endpoint_id)
    hash[:endpoint_id] = endpoint.id
    hash[:company_id] = endpoint.company_id
    hash
  end

  def signature
    "WebhookDeliveryJob-#{@company_id}-#{@endpoint_id}-#{self.job_id}"
  end
  
  class Runner
    attr_reader :endpoint, :event_name, :object, :events

    def initialize(endpoint, event_name, gid)
      @endpoint = endpoint
      @event_name = event_name
      @object = GlobalID::Locator.locate(gid)
      @events = []
    end

    def conditions_str
      @conditions_str ||= Webhook::PayloadGenerator.generate(object, event_name, endpoint.conditions_template)
    end

    def payload_str
      @payload_str ||= Webhook::PayloadGenerator.generate(object, event_name, endpoint.payload_template, escape_values: endpoint.escape_all_values)
    end

    def req_headers
      @req_headers ||= request_headers(endpoint)
    end

    def filtered_req_headers
      @filtered_req_headers ||= filter_headers_for_logging(req_headers)
    end

    def perform!
      return record_skipped_attempt! unless matches_conditions?

      begin
        response = request(endpoint, payload_str, req_headers)
      rescue => e
        # note: this block is for unusual exceptions like socket error, certificate error, etc.
        #       responses with non-success codes are already handled above
        Rails.logger.warn("Caught exception in webhook request: #{e}")
        Rails.logger.warn(e.backtrace.join("\n"))
        response = OpenStruct.new(body: e.message, code: 500)
      ensure
        create_event(endpoint, event_name, payload_str, req_headers, response)
        disable_endpoint_if_necessary_and_notify_admins(endpoint)
      end
    end

    # The Liquid template in #conditions_template should evaluate to the string "true".
    # Whitespace will be stripped.
    def matches_conditions?
      return true if endpoint.conditions_template.blank?
      
      formatted_str = conditions_str.strip.downcase
      formatted_str == "true"
    end
    
    def record_skipped_attempt!
      response = OpenStruct.new({
        body: _("Webhook was skipped. Conditions were not met: \nTemplate: #{endpoint.conditions_template}\nEvaluated to: #{conditions_str}"),
        code: 'skipped'
      })
      create_event(endpoint, event_name, payload_str, req_headers, response)
    end

    private

    def create_event(endpoint, event_name, payload_str, request_headers, response)
      request_attrs = {
        request_payload: payload_str,
        request_headers: filter_headers_for_logging(request_headers)
      }

      response_attrs = {
        response_payload: response.body,
        response_headers: response.headers,
        response_status_code: response.code
      }

      Webhook::Event.create_from_endpoint!(endpoint,
                                           name: event_name, **request_attrs, **response_attrs).tap do |event|
        @events << event
      end
    end

    def request(endpoint, payload, headers)
      # using block syntax to prevent exceptions from being raised for non-success responses
      RestClient::Request.execute(method: endpoint.request_method,
                                  url: endpoint.target_url,
                                  headers: headers,
                                  payload: payload) { |response, _request, _result| response }
    end

    def request_headers(endpoint)
      {
        content_type: :json
      }.tap do |h|
        if endpoint.request_headers.present?
          header_template = Liquid::Template.parse(endpoint.request_headers)
          parseable_header_vars = {authentication_token: endpoint.authentication_token || ''}
          rendered_headers = header_template.render(parseable_header_vars.stringify_keys)
          hashed_headers = JSON.parse(rendered_headers)
          h.merge!(hashed_headers)
        end
      end
    end

    def filter_headers_for_logging(headers)
      headers.dup.tap do |h|
        if (auth_header = h["Authorization"]).present?
          # redact all whitespace separated sub-strings except 'Bearer'
          h["Authorization"] = auth_header.split.map do |str|
            str == 'Bearer' ? str : '[filtered]'
          end.join(' ')
        end
      end
    end

    # note: it is assumed that the event for current response has already been created
    def disable_endpoint_if_necessary_and_notify_admins(endpoint)
      return unless endpoint.eligible_for_auto_disable?

      endpoint.update(is_active: false)
      WebhookNotifier.notify_endpoint_disabled(endpoint).deliver_now
    end
  end # end Runner class
end
