class AllowYammerConnect < ActiveRecord::Migration[4.2]
  def up
    add_column :companies, :allow_yammer_connect, :boolean, default: true
  end

  def down
  end
end
