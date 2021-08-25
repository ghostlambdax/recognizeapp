class MakeEmailLoggerHaveLongTextBody < ActiveRecord::Migration[4.2]
  def change
    change_column :email_logs, :body, :text, limit: 4294967295
  end
end
