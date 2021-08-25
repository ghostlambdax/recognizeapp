class AddNullConstraintForBadgesOnRecognition < ActiveRecord::Migration[4.2]
  def change
    change_column :recognitions, :badge_id, :integer, :null => false
  end
end
