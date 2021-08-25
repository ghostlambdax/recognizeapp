class AddReasonToRecognitions < ActiveRecord::Migration[4.2]
  def change
    add_column :recognitions, :reason, :string
  end
end
