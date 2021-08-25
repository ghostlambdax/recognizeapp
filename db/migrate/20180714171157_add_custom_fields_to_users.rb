class AddCustomFieldsToUsers < ActiveRecord::Migration[5.0]
  def change
    (0..9).each do |index|
      add_column :users, "custom_field#{index}", :string rescue nil
    end
  end
end
