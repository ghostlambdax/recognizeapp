class AddColumnsToPlans < ActiveRecord::Migration[4.2]
  def change
    add_column :plans, :is_public, :boolean, default: true
    add_column :plans, :interval, :string, default: "monthly"
    FactoryBot.create(:business_plan) unless Plan.exists?(name: "business200")

  end

end
