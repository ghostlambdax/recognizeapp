class PointsRequester
  include ActiveModel::Model
  include Rails.application.routes.url_helpers

  attr_accessor :company, :user, :amount, :type_of_payment, :currency
  validates :company, :user, :amount, :currency, presence: true
  validates_numericality_of :amount, greater_than: 0, allow_blank: true
  # validate :all_badges_have_send_limits

  def send!
    SystemNotifier.delay(queue: 'priority').points_deposit self
  end

  # hack for ajaxify
  def persisted?
    company.present? && valid?
  end

  def attributes
    {
      amount: self.amount,
      type_of_payment: self.type_of_payment
    }
  end

  private
  # def all_badges_have_send_limits 
  #   if company.company_badges.non_nominations.without_sending_limit.size > 0
  #     errors.add(:base, "Please set all your badges to have a sending limit.<br>Otherwise, staff can send more points than they can redeem.")
  #   end
  # end
end
