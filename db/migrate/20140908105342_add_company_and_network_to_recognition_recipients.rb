class AddCompanyAndNetworkToRecognitionRecipients < ActiveRecord::Migration[4.2]
  def change
    add_column :recognition_recipients, :recipient_company_id, :integer
    add_column :recognition_recipients, :recipient_network, :string
  end
end
