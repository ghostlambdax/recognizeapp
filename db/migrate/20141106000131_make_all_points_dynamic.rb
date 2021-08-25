class MakeAllPointsDynamic < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :point_values, :text
  end
end
