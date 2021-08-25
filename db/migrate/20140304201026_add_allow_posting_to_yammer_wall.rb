class AddAllowPostingToYammerWall < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :allow_posting_to_yammer_wall, :boolean, default: false
  end
end
