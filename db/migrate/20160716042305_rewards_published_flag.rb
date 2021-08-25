class RewardsPublishedFlag < ActiveRecord::Migration[4.2]
  def change
    add_column(:rewards, :published, :boolean, default: false)
  end
end
