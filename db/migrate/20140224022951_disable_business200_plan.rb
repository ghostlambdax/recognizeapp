class DisableBusiness200Plan < ActiveRecord::Migration[4.2]
  def up
    Plan.where(name: "business200").first.update_attribute(:is_public, false)
  end

  def down
    Plan.where(name: "business200").first.update_attribute(:is_public, true)
  end
end
