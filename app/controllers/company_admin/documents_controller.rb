# frozen_string_literal: true

class CompanyAdmin::DocumentsController < CompanyAdmin::BaseController
  include AdminDocumentsConcern

  private

  def datatable
    DocumentsDatatable.new(view_context, @company)
  end

  def document_scope
    @company.documents
  end
end
