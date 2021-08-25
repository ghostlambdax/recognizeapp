class ChangeBirthdayAndStartDateTypes < ActiveRecord::Migration[4.2]
  def change
    change_column :users, :birthday, :date
    change_column :users, :start_date, :date
  end
end
