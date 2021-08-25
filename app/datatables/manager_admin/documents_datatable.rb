require 'will_paginate/array'

class ManagerAdmin::DocumentsDatatable < DocumentsDatatable

  def all_records
    documents = company.documents.accessible_by_manager_admin(current_user).includes(:requester, :uploader)
    documents = params[:type] == "uploads" ? documents.uploads : documents.downloads
    documents = documents.order(sort_columns_and_directions) if params[:order].present?
    documents
  end
end
