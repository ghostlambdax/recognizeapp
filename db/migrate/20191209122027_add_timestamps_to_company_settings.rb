# Note: allowing null values for existing records.
class AddTimestampsToCompanySettings < ActiveRecord::Migration[5.0]
  def change
    change_table :company_settings do |t|
      t.datetime :created_at
      t.datetime :updated_at
    end
  end
end
