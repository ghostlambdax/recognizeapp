class AddInputFormatToRecognitions < ActiveRecord::Migration[5.0]
  def change
    add_column :recognitions, :input_format, :string, default: 'text'
  end
end
