class AddPhoneToSupportRequests < ActiveRecord::Migration[4.2]
  def change
    add_column :support_emails, :phone, :string
  end
end
