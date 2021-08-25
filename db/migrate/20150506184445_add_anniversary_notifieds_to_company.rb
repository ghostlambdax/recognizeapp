class AddAnniversaryNotifiedsToCompany < ActiveRecord::Migration[4.2]
  def change
  	add_column :companies, :anniversary_notifieds, :text
  end
end
