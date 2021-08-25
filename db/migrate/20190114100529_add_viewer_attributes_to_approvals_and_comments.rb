class AddViewerAttributesToApprovalsAndComments < ActiveRecord::Migration[5.0]
  def change
    %i[recognition_approvals comments].each do |table_name|
      change_table(table_name, bulk: true) do |t|
        t.column :viewer, :string
        t.column :viewer_description, :string
      end
    end
  end
end
