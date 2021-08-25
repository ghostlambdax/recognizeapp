class AddInstantFlagToRecognitions < ActiveRecord::Migration[4.2]
  def change
    add_column :recognitions, :is_instant, :boolean, default: false
  end
end
