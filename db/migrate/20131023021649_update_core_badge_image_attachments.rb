class UpdateCoreBadgeImageAttachments < ActiveRecord::Migration[4.2]
  def up
    #Badge.unscoped.where("company_id IS NULL").each do |b|
    #  b.image = b.local_file
    #  b.save!
    #end
  end

  def down
  end
end
