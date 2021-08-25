class ChangeSurveyDataToText < ActiveRecord::Migration[4.2]
  def change
    change_column :surveys, :data, :text, limit: 4294967295
  end
end
