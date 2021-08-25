class CreateCompanySettings < ActiveRecord::Migration[4.2]
  def change
    create_table :company_settings do |t|
      t.integer :company_id
      t.string :fb_workplace_community_id
      t.text :fb_workplace_token
      t.string :fb_workplace_post_to_group_id
      t.boolean :fb_workplace_enable_post_to_group, default: false
      t.text :profile_badge_ids
    end
  end
end
