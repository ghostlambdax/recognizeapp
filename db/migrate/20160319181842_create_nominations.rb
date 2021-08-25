class CreateNominations < ActiveRecord::Migration[4.2]
  def change
    create_table :nominations do |t|
      t.belongs_to :badge, index: true
      t.belongs_to :sender, index: true
      t.references :recipient, polymorphic: true, index: true
      t.text :message
      t.belongs_to :sender_company, index: true

      t.timestamps
    end
  end
end
