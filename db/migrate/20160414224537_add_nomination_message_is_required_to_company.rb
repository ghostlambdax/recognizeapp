class AddNominationMessageIsRequiredToCompany < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :nomination_message_is_required, :boolean, default: false
  end
end
