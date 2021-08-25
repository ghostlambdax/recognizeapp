module AccountsHelper
  def add_account_row_template(f, id)
    user = User.new
    user.id = id
    row = fields_for("bulk_user_updater[]", user) do |user_form|
      render("account_row", user_form: user_form, user: user, new_row: true)
    end
    return row.gsub("\n", "")
  end

  def link_to_add_new_account_row(f)
    id = Time.now.to_f.to_s.gsub('.','')
    link_to "Add user", "javascript://none", class: "button", id: "add-account",
      data: {id: id, new_account_template: add_account_row_template(f, id)}
  end

  def last_accounts_spreadsheet_import_results_document_path(company)
    company_admin_document_path(company.last_accounts_spreadsheet_import_results_document, network: company.domain)
  end

  def last_accounts_spreadsheet_import_was_problematic?(company)
    return false if company.last_accounts_spreadsheet_import_summary.blank?

    import_summary = company.last_accounts_spreadsheet_import_summary
    import_summary.failed_records_count.positive? || import_summary.saved_but_require_attention_records_count.positive?
  end
end
