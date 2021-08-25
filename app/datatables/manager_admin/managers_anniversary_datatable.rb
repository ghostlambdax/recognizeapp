# frozen_string_literal: true

class ManagerAdmin::ManagersAnniversaryDatatable < UsersAnniversaryDatatable
  def all_records
    super.where(manager_id: current_user.id)
  end
end
