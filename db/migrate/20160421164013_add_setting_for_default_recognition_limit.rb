class AddSettingForDefaultRecognitionLimit < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :default_recognition_limit_frequency, :integer
    add_column :companies, :default_recognition_limit_interval_id, :integer
  end
end
