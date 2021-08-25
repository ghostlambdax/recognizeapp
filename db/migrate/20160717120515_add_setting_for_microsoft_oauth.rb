class AddSettingForMicrosoftOauth < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :allow_microsoft_graph_oauth, :boolean, default: true
  end
end
