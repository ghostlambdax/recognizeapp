class ChangeDefaultValueOfLimitScopeForBadgesAndCompanies < ActiveRecord::Migration[4.2]
  def change
    send_limit_scope_id = Recognition::LimitScope::SCOPE_LIMIT_BY_USERS
    change_column_default :companies, :default_recognition_limit_scope_id, send_limit_scope_id
    change_column_default :companies, :recognition_limit_scope_id, send_limit_scope_id
    change_column_default :badges, :sending_limit_scope_id, send_limit_scope_id
  end
end
