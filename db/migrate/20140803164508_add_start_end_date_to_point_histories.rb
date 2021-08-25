class AddStartEndDateToPointHistories < ActiveRecord::Migration[4.2]
  def change
    remove_column :point_histories, :date, :date
    add_column :point_histories, :start_date, :date
    add_column :point_histories, :end_date, :date
    PointHistory.delete_all
  end
end
