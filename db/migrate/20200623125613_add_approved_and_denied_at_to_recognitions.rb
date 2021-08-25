class AddApprovedAndDeniedAtToRecognitions < ActiveRecord::Migration[5.0]
  def up
    add_column :recognitions, :approved_at, :datetime
    add_column :recognitions, :denied_at, :datetime

    # denied_status_id = Recognition.status_id_by_name(:denied)
    # approved_status_id = Recognition.status_id_by_name(:approved)
    # system_user_id = User.system_user.id
    # puts "updating approved_at and denied_at attributes for recognitions"
    # begin
    #   # Denied recognitions
    #   Recognition.where(status_id: denied_status_id).update_all("denied_at=updated_at")
    #   # Manually approved recognitions
    #   Recognition.where(status_id: approved_status_id).where.not(resolver_id: system_user_id).update_all("approved_at=updated_at")
    #   # Auto approved recognitions
    #   Recognition.where(status_id: approved_status_id).where(resolver_id: system_user_id).update_all("approved_at=created_at")
    # rescue => e
    #   Rails.logger.warn "Data migration failed! #{e}"
    # end
  end

  def down
    remove_column :recognitions, :approved_at
    remove_column :recognitions, :denied_at
  end
end
