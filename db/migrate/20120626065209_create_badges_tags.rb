class CreateBadgesTags < ActiveRecord::Migration[4.2]
  def change
    create_table :badges_tags, :id => false do |t|
      t.integer :badge_id
      t.integer :tag_id
    end
  end
end
