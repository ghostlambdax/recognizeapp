module CompanyAdmin
  class WebhookEndpointsController < CompanyAdmin::BaseController
    def index
      @webhooks = @company.webhook_endpoints
      render "index", layout: false
    end

    def create
      @webhook_endpoint = @company.webhook_endpoints.new(webhook_endpoint_params)
      @webhook_endpoint.owner = current_user
      respond_with @webhook_endpoint unless @webhook_endpoint.save
    end

    def update      
      @webhook_endpoint = @company.webhook_endpoints.find(params[:id])
      respond_with @webhook_endpoint unless @webhook_endpoint.update(webhook_endpoint_params)
    end

    def destroy      
      @webhook_endpoint = @company.webhook_endpoints.find(params[:id])
      @webhook_endpoint.destroy
    end

    def events
      @webhook_endpoint = @company.webhook_endpoints.find(params[:id])
      @webhook_events = @webhook_endpoint.events.order(created_at: :desc).limit(Webhook::Event.recent_limit)
    end

    def event_objects
      @webhook_endpoint = @company.webhook_endpoints.find(params[:id])
      @webhook_objects = @webhook_endpoint.recent_objects.each_with_object([]) do |o, array|
        label = "#{o.created_at.to_formatted_s(:db)}(#{o.recognize_hashid}) - #{o.summary_label}"
        array << {id: o.to_global_id.to_s, text: label} if params[:q].blank? || label.match(Regexp.escape(params[:q]))
      end
      respond_with({results: @webhook_objects}, root: false)
    end

    def show_test_payload
      @webhook_endpoint = @company.webhook_endpoints.find(params[:id])
      # we want to apply the attributes without saving just for the purposes of sending the test hook.
      # Its a bit touchy as WebhookDeliveryJob::Runner needs to make sure not to save the endpoint
      # in the course of delivering the hook. But that should be ok and just need a test to cover it. 
      @webhook_endpoint.assign_attributes(webhook_endpoint_params)
      @runner = WebhookDeliveryJob::Runner.new(@webhook_endpoint, @webhook_endpoint.subscribed_event, params[:object_gid])
    end

    def send_test_webhook
      @webhook_endpoint = @company.webhook_endpoints.find(params[:id])
      # we want to apply the attributes without saving just for the purposes of sending the test hook.
      # Its a bit touchy as WebhookDeliveryJob::Runner needs to make sure not to save the endpoint
      # in the course of delivering the hook. But that should be ok and just need a test to cover it. 
      @webhook_endpoint.assign_attributes(webhook_endpoint_params.except(:authentication_token))
      @runner = WebhookDeliveryJob::Runner.new(@webhook_endpoint, @webhook_endpoint.subscribed_event, params[:object_gid])
      @runner.perform!      
    end

    private
    def webhook_endpoint_params
      required_params = params.require(:webhook_endpoint)

      # The webhook_endpoint form is indexed on edit because there are multiple on a single page
      # so that gives unique ids for each element.
      # But that also screws with how the form data is submitted depending on if its new/edit
      # edit form {"webhook_endpoint" => {"3" => {...}}}
      # I originally wanted to pass the index, even if null, for consistency
      # but really struggled to get checkboxes to work since they are handled like arrays
      # which messed with rails handling of the rest of the array based parameters due to index
      required_params = required_params.require(params[:id]) if params[:id].present?
      
      permit_attrs = [:is_active, :description, :subscribed_event, :target_url, :request_method, :payload_template, :conditions_template, :request_headers, :escape_all_values]
      permit_attrs << :authentication_token unless params.key?(:authentication_token?) && required_params.fetch(:authentication_token) == Webhook::Endpoint.token_mask_stars
      required_params.permit(permit_attrs)
    end
  end
end
