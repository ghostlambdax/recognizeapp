# frozen_string_literal: true

class ManagerAdmin::DocumentsController < ManagerAdmin::BaseController
  include AdminDocumentsConcern

  private

  def datatable
    ManagerAdmin::DocumentsDatatable.new(view_context, @company)
  end

  def document_scope
    @company.documents.accessible_by_manager_admin(current_user)
  end
end
