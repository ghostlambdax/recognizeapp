class EnsureAllRecognitionsStashTheirPermalinks < ActiveRecord::Migration[4.2]
  def up
#    Recognition.with_deleted.all.each do |r|
#      r.send(:generate_slug) if r.slug.blank?
#    end
  end
end
