class AddYearlyPlan < ActiveRecord::Migration[4.2]
  def up
    FactoryBot.create(:business_100_yearly_plan)
  end

  def down
    Plan.where(name: :business100Yearly).destroy_all
  end
end
