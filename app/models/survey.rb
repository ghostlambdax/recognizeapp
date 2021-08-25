class Survey < ApplicationRecord
  serialize :data, Hashie::Mash
  validates :data, :email, presence: true

  after_create :send_email
  after_create :crm_lead_creation

  protected
  def send_email
    SystemNotifier.delay(queue: 'priority').survey_response(self)
  end

  def crm_lead_creation
    close = Recognize::Application.closeio

    data = self[:data]
    name = self[:data][:full_name]
    sales_entry = 'Engagement doc'

    user = User.new(email: email, first_name: name)

    fields = {}
    fields[close.get_custom_field_id_by_name('Sales entry')] = sales_entry
    fields[close.get_custom_field_id_by_name('Employee size')] = self[:data][:num_of_users]
    fields[close.get_custom_field_id_by_name('Reward budget')] = self[:data][:rewards_budget]
    fields[close.get_custom_field_id_by_name('@QuickMail Sequence')] = 'Engagement doc request - Owned by Alex Grande #65787'
    fields["status_id"] = close.get_lead_status_id_by_name("Contacted")

    close.delay(queue: 'sales').upsert_contact(user, fields)
  end

end
