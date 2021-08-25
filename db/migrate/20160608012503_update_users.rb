class UpdateUsers < ActiveRecord::Migration[4.2]
  def change
    add_column(:users, :disabled_at, :timestamp)
  end
end
