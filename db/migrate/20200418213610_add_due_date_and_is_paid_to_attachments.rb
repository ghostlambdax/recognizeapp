class AddDueDateAndIsPaidToAttachments < ActiveRecord::Migration[5.0]
  def change
    add_column :attachments, :due_date, :date
    add_column :attachments, :is_paid, :boolean
  end
end
