class AddColumnsForQuickNominations < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :nomination_global_award_limit_interval_id, :integer
    add_column :badges, :nomination_award_limit_interval_id, :integer
    add_column :badges, :is_quick_nomination, :boolean, default: false
    add_column :users, :last_nomination_awarded_at, :datetime
  end
end
