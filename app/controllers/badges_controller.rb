require "will_paginate/array"
class BadgesController < ApplicationController
  include SharedParamsConcern
  show_upgrade_banner only: [:index]
  before_action :set_gon_stream_comments_and_approvals_path, only: [:show]

  def index
    @badges = current_user.company.company_badges.show_in_badge_list.sort_with_order
  end

  def show
    @badge = current_user.company.company_badges.find(params[:id])
    @recognitions = current_user.company.recognitions_for_badge(params[:id]).paginate(:page => params[:page], :per_page => 15)
  end

  def new
    @badge = @company.badges.build
  end

  def create
    @badge  = Badge.new(badge_params)
    @badge.company = @company
    @badge.save

    if handle_ie_stupidity?
      handle_ie_stupidity

    else
      if @badge.persisted?
        @company_roles = @company.company_roles
        render json: { partial: render_to_string(partial: "companies/badge", locals: {badge: @badge}) }
      else
        respond_with @badge
      end
    end
  end

  def update_image
    @badge = Badge.find(params[:badge_id])
    @badge.image = params[:image]
    @badge.save

    if @badge.valid?
      render json: { badge_id: @badge.id, badge_image_url: @badge.permalink(200) }
    else
      render json: { errors: @badge.errors, status: :unprocessable_entity }
    end
  rescue StandardError, ImageAttachmentUploader::ImproperFileFormat => e
    render json: { errors: {base: [e.message]}}, status: :unprocessable_entity
  end

  def update_all
    # To prevent the update to error out when there are no badges present
    if params[:company].blank?
      flash[:error] = "There are no badges present to be updated"
    else
      result = @company.update_badges!(badge_mass_params)
      if result.success
        flash[:notice] = "Successfully updated badges"
      else
        # FIXME: this shouldn't redirect t
        badges_with_errors = result.badges.reject{|b| b.errors.size == 0}
        flash[:error] = error_message_for_batch_update(badges_with_errors.count)
        flash[:badge_errors] = badges_with_errors.inject({}){|hash, badge| hash[badge.id] = badge.errors.full_messages;hash}
      end
    end
    redirect_to company_path(network: current_user.network, anchor: "custom_badges", dept: @company.domain, status: params[:badges_status])
  end

  def destroy
    @badge = Badge.find(params[:id])
    @badge.destroy if @badge.can_destroy?
  end

  def remaining
    badges_remaining = BadgesRemainingCalculator.recognition_badges_remaining(current_user)
    render json: {badges: badges_remaining}.to_json
  end

  private
  def handle_ie_stupidity?
    !request.headers["HTTP_ACCEPT"].match(/application\/json|application\/javascript/)
  end

  def handle_ie_stupidity
    request.format = 'json'

    resource = JsonResource.new(@badge, self, [], {})
    if resource.has_errors?
      status = 422
      render :json => resource.to_json, :content_type => "text/plain", status: status
    else
      status = 200
      render json: { partial: render_to_string(partial: "companies/badge", content_type: "text/plain", locals: {badge: @badge}) }

    end

  end

  def badge_mass_params
    string_params = %w[short_name enabled description long_description points
                       sending_frequency sending_interval_id show_in_badge_list force_private_recognition
                       nomination_award_limit_interval_id is_nomination is_quick_nomination allow_self_nomination
                       is_instant is_achievement achievement_frequency achievement_interval_id requires_approval approval_strategy sort_order]
    array_params = %w[roles point_values approver]

    allowed_badge_params = string_params + array_params
    # perform manual whitelisting since strong params does not support deep nested hashes with dynamic keys
    params.require(:company).require(:badges)
      .to_unsafe_h
      .select{|k, _v| k =~ /\A\d+\z/ }
      .transform_values do |attr_hash|
        attr_hash
          .slice(*allowed_badge_params)
          .select do |attr, val|
            val.is_a?(String) ||
              (val.is_a?(Array) && array_params.include?(attr))
          end
      end
  end

  def error_message_for_batch_update(error_count)
    if error_count == 1
      flash[:error] = "There was an error with one of the badges. Please see the highlighted badge below."
    else
      flash[:error] = "There were errors with #{error_count} badges. Please see the highlighted badges below."
    end
  end
end
