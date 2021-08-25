class Create395YearlyPlan < ActiveRecord::Migration[4.2]
  def up
    FactoryBot.create(:business_0395_yearly_plan)
    Plan.where(name: "business2400Yearly").first.update_attribute(:is_public, false)
  end

  def down
    Plan.where(name: "business395yearly").destroy_all
  end
end
