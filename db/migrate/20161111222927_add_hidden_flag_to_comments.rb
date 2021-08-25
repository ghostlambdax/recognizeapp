class AddHiddenFlagToComments < ActiveRecord::Migration[4.2]
  def change
    add_column :comments, :is_hidden, :boolean, default: false
  end
end
