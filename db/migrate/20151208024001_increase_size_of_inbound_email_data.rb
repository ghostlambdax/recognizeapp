class IncreaseSizeOfInboundEmailData < ActiveRecord::Migration[4.2]
  def change
    change_column :inbound_emails, :data, :text, :limit => 4294967295
  end
end
