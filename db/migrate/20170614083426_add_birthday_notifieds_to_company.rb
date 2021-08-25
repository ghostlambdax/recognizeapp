class AddBirthdayNotifiedsToCompany < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :birthday_notifieds, :text
  end
end
