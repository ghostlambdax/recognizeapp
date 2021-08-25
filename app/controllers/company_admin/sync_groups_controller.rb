module CompanyAdmin
  class SyncGroupsController < CompanyAdmin::BaseController
    def index
      respond_to do |format|
        format.html do
          @selected_sync_groups = @company.sync_groups(provider: params[:provider])
          @lazy_load = UserSync::Base.factory(params[:provider]).lazy_load?
          if params[:provider] == 'microsoft_graph'
            @available_sync_groups = @selected_sync_groups # render only selected groups initially
          else
            @available_sync_groups, @error = fetch_sync_groups.values_at(:groups, :error)
          end
          render "index", layout: false
        end

        # Currently used for Microsoft Graph only
        format.json do
          if params[:term].blank?
            return render json: { error: 'Search term cannot be blank' }, status: 422
          end

          sync_groups, skip_token, error = fetch_sync_groups(use_skip_token: true)
                                             .values_at(:groups, :skip_token, :error)
          if error
            render json: { error: error }, status: 401
          else
            response_hash = {
              values: sync_groups.map {|g| g.slice('id', 'displayName')},
            }

            if skip_token
              response_hash[:remote_params] = { skip_token: skip_token }
              response_hash[:has_more] = true
            end

            render json: response_hash
          end
        end
      end
    end

    def create
      @company.settings.add_sync_group(group, params[:provider])
      head :ok
    end

    def destroy
      group_id = params[:group_id] || params[:id]
      @company.settings.remove_sync_group(group_id, params[:provider])
      head :ok
    end

    private

    def fetch_sync_groups(use_skip_token: false)
      sync_groups = []
      skip_token = error = nil

      begin
        provider = params[:provider] || @company.sync_provider
        if provider.to_sym != :sftp
          user = @company.admin_sync_user(provider: provider)
          term = params[:term]
          if use_skip_token
            provided_skip_token = params.dig(:remote_params, :skip_token)
            sync_groups, skip_token = SyncGroupService.fetch_with_skip_token_for(user, provider,
                                                                                 search_term: term, skip_token: provided_skip_token)
          else
            sync_groups = SyncGroupService.fetch_for(user, provider, search_term: term)
          end
        end
      rescue SyncGroupService::Error => e
        error = e.message
      end

      { groups: sync_groups, error: error, skip_token: skip_token }
    end

    def group
      case params[:provider].to_sym || @company.sync_provider.to_sym
      when :yammer
        yammer_client.get_group(params[:group_id] || params[:id])
      when :microsoft_graph
        microsoft_graph_client.group(params[:group_id] || params[:id])
      end
    end

    def yammer_client
      YammerClient.new(current_user.yammer_token, current_user)
    end

    def microsoft_graph_client
      MicrosoftGraphClient.new(current_user.microsoft_graph_token, current_user)
    end
  end
end
