class AddEarnedPointsToRecognition < ActiveRecord::Migration[5.0]
  def change
    add_column :recognitions, :earned_points, :integer

    # Update all historic recognition.
    Recognition.find_each do |recognition|
      recognition.update_column(:earned_points, recognition.earned_points_calculated_off_point_activities)
    end
  end
end
