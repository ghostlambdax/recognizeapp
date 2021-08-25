class AddAnotherYearlyPlan < ActiveRecord::Migration[4.2]
  def up
    FactoryBot.create(:business_2400_yearly_plan)
    Plan.where(name: "business100Yearly").update_all(["is_public = ?", false])
  end

  def down
    Plan.where(name: "business100Yearly").update_all(["is_public = ?", true])
    Plan.where(name: "business2400Yearly").destroy_all
  end
end
