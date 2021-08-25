# frozen_string_literal: true

class ExternalDataController < ApplicationController
  before_action :ensure_yammer_groups_options_sanity, only: :yammer_groups

  def yammer_groups
    default_group_id_to_post_to = current_user.company.post_to_yammer_group_id
    available_groups = begin
      groups = if params[:groups_scope] == "company"
        ProviderGroupService.yammer_groups_for_company(current_user)
      elsif params[:groups_scope] == "user"
        ProviderGroupService.yammer_groups_for_user(current_user)
      end
      groups.reject{ |group| group.restricted_posting == true }
    end
  rescue ProviderGroupService::Error => e
    render json: "Failed to retrieve groups from Yammer!", status: :internal_server_error
  else
    render json: { available_groups: available_groups, default_group_id: default_group_id_to_post_to }
  end

  private

  def ensure_yammer_groups_options_sanity
    supported_groups_scope = %w[company user]
    supported_clients = %w[recognitions_new recognitions_new_chromeless recognitions_new_panel company_admin/settings_index, company_admin/settings_index]

    raise ArgumentError, "Unsupported 'groups_scope' - #{params[:groups_scope]}" unless params[:groups_scope].in? supported_groups_scope
    raise ArgumentError, "Unsupported 'client' - #{params[:client]}" unless params[:client].in? supported_clients
  end
end
