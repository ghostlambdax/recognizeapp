class AddFeedbackTypeParamToContactForm < ActiveRecord::Migration[4.2]
  def change
    add_column :support_emails, :type, :string
  end
end
