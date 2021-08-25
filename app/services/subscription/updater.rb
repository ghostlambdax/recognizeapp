class Subscription::Updater
  include Subscription::Common

  attr_reader :company, :user, :params, :subscription

  def self.update(company, user, params)
    new(company, user, params).update
  end

  def update
    @subscription = company.subscription

    transaction do
      before_save
      @subscription.update(params)
      if @subscription.errors.empty? && !@subscription.cancelled?
        plan = Plan::Syncer.sync!(@subscription)
        @subscription.update_column(:plan_id, plan.id)
      end
    end
    return @subscription
  rescue ActiveRecord::RecordInvalid => e
    return @subscription
  rescue => e
    @subscription.errors.add(:base, I18n.t("activerecord.errors.models.subscription.failed_to_save", message: e.message))
    return @subscription    
  end

  private

end