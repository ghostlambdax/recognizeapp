class AllowRecognizeCompanyToHaveCustomBadgs < ActiveRecord::Migration[4.2]
  def up
    #Badge.unscoped do
    #  c = Company.where(domain: "recognizeapp.com").first
    #  c.enable_custom_badges! if c.present?
    #end
  end

  def down
  end
end
