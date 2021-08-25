class AddPrivacyFlagToRecognitions < ActiveRecord::Migration[4.2]
  def change
    add_column :recognitions, :is_public, :boolean, default: false
  end
end
