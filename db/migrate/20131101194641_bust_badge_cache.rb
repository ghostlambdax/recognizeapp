class BustBadgeCache < ActiveRecord::Migration[4.2]
  def up
    #Badge.unscoped.all.each do |b|
    #  Rails.cache.delete("Badges/#{b.id}")
    #  Badge.cached(b.id)
    #end
  end

  def down
  end
end
