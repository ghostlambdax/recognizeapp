class UpdateO365AuthToMsGraph < ActiveRecord::Migration[4.2]
  def up
    Authentication.where(provider: "office365").update_all(provider: "microsoft_graph")
  end
end
