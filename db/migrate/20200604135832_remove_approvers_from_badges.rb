class RemoveApproversFromBadges < ActiveRecord::Migration[5.0]
  def change
    remove_column :badges, :approvers
  end
end
