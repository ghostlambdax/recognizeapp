class CreateSupportEmails < ActiveRecord::Migration[4.2]
  def change
    create_table :support_emails do |t|
      t.string :name
      t.string :email
      t.text :message

      t.timestamps
    end
  end
end
