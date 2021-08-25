class AddPrivateToRecognition < ActiveRecord::Migration[4.2]
  def change
    add_column :recognitions, :is_private, :boolean, default: false, nil: false
    add_column :companies, :allows_private, :boolean, default: true, nil: false
  end
end
