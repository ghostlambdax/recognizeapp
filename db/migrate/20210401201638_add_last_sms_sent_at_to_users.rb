class AddLastSmsSentAtToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :last_sms_sent_at, :datetime
  end
end
