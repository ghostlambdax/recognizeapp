module DocumentsHelper
  def admin_type
    manager_admin_controller? ? :manager_admin : :company_admin
  end

  def documents_index_endpoint(opts = {})
    send("#{admin_type}_documents_path", opts)
  end

  def documents_create_endpoint
    send("#{admin_type}_documents_path")
  end

  def document_show_endpoint(document)
    send("#{admin_type}_document_path", document)
  end

  def document_destroy_endpoint(document)
    send("#{admin_type}_document_path", document)
  end

end
