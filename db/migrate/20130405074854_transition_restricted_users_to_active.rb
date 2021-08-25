class TransitionRestrictedUsersToActive < ActiveRecord::Migration[4.2]
  def up
    User.with_deleted.where(status: 'restricted').update_all("status='active'")
  end

  def down
  end
end
