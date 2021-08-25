class ChangeYammerWallPostToTrue < ActiveRecord::Migration[4.2]
  def up
    change_column :companies, :allow_posting_to_yammer_wall, :boolean, default: true
  end

  def down
  end
end
