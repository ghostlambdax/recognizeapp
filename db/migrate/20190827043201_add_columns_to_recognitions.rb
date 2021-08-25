class AddColumnsToRecognitions < ActiveRecord::Migration[5.0]
  def change
    add_column :recognitions, :from_bulk, :boolean, default: false
    add_column :recognitions, :skip_notifications, :boolean, default: false
  end
end
