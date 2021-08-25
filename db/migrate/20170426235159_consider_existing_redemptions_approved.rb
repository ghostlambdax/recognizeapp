class ConsiderExistingRedemptionsApproved < ActiveRecord::Migration[4.2]
  def up
    Redemption.update_all(status: :approved, approver_id: 1)
    Redemption.update_all("approved_at=created_at")
  end
end
