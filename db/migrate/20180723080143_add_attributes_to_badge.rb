class AddAttributesToBadge < ActiveRecord::Migration[5.0]
  def change
    add_column :badges, :requires_approval, :boolean, default: false
    add_column :badges, :point_values, :text
    add_column :badges, :approvers, :text
  end
end
