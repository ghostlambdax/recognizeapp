class AddSettingForQuickNominations < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :allow_quick_nominations, :boolean, default: false
  end
end
