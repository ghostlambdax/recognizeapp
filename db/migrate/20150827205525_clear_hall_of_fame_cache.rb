class ClearHallOfFameCache < ActiveRecord::Migration[4.2]
  def up
    Rails.cache.delete_matched(/HallOfFame/)
  end
end
