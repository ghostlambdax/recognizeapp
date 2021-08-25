class AddThreadIdToRecogntions < ActiveRecord::Migration[4.2]
  def change
    add_column :recognitions, :yammer_thread_id, :string
  end
end
