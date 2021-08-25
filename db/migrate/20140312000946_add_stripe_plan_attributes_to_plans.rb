class AddStripePlanAttributesToPlans < ActiveRecord::Migration[4.2]
  def change
    add_column :plans, :stripe_attributes, :text
  end
end
