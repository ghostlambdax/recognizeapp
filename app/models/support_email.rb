class SupportEmail < ApplicationRecord

  self.inheritance_column = :_type_disabled

  validates :name, presence: true
  validates :message, presence: true, if: ->{ type.to_s.downcase == "support"}
  validates :phone, presence: true, if: ->{ type.to_s.downcase == "sales"}
  validates :email, presence: true

  after_save :notify_management

  # NOTE: as of 1/19/2016, rails v4.1.14 (updated 12/14/2017)
  #       there seems to be a bug that reverses after_commit ordering
  #       https://github.com/rails/rails/issues/20911
  #       This issue is now closed, although the PR is outstanding
  #
  #       The proper ordering is save phone to user and then notify close
  #       (so it picks up the users phone number during upsert)
  #
  #       For now, reverse the order, and raise exception if version changes
  #       so we know to double check this ordering on every upgrade until fixed

  #       The issue is still open so keeping the manual sorting

  # NOTE: As of 3/18/2021, this issue is still open.

  raise "DoubleCheckRailsBugForAfterCommitReverseOrdering" unless Rails.version == "6.0.3.7"

  after_commit :notify_closeio, if: :sales?
  after_commit :save_phone_to_user, if: ->{ phone.present? } #should run first

  def notify_closeio
    close = Recognize::Application.closeio
    user = User.find_or_initialize_by(email: self.email)
    user.first_name = self.name

    fields = {}
    fields[close.get_custom_field_id_by_name('Sales entry')] = "Sales request"
    fields["status_id"] = close.get_lead_status_id_by_name("Contacted")

    close.delay(queue: 'sales').upsert_contact(user.id, fields)
  rescue => e
    ExceptionNotifier.notify_exception(e, {data: {email: email}})
  end

  def support?
    type.to_s.downcase == 'support'
  end

  def sales?
    type.to_s.downcase == 'sales'
  end

  protected
  def notify_management
    SystemNotifier.delay(queue: 'priority').contact_email(self)
  end

  def save_phone_to_user
    user = User.find_by(email: self.email)
    user.update_column(:phone, self.phone) if user.present?
  end
end
