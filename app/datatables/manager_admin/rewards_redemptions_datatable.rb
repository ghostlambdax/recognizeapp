require 'will_paginate/array'
class ManagerAdmin::RewardsRedemptionsDatatable < RewardsRedemptionsDatatable
  def all_records
    redemptions = @company.redemptions.managed_by(current_user).joins(reward_variant: { reward: :catalog})
    redemptions = redemptions.where(status: params['status']) if ['approved', 'denied', 'pending'].include? params['status']
    redemptions = redemptions.order("#{sort_columns_and_directions}") if params[:order].present?
    return redemptions.includes(:user, reward_variant: { reward: :catalog })
  end
end
