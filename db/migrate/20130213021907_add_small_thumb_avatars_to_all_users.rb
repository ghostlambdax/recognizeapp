class AddSmallThumbAvatarsToAllUsers < ActiveRecord::Migration[4.2]
  def up
    set = AvatarAttachment.all.select{|a| a.file.small_thumb.blank?}
    set.each{|s| s.recreate_versions! rescue nil}
  end
end
