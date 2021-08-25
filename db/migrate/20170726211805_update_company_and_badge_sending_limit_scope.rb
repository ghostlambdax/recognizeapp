class UpdateCompanyAndBadgeSendingLimitScope < ActiveRecord::Migration[4.2]
  def up
    send_limit_scope_id = Recognition::LimitScope::SCOPE_LIMIT_BY_USERS
    Company.update_all(default_recognition_limit_scope_id: send_limit_scope_id, recognition_limit_scope_id: send_limit_scope_id)
    Badge.update_all(sending_limit_scope_id: send_limit_scope_id)
  end
end
