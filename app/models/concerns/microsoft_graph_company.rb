module MicrosoftGraphCompany
  def has_at_least_one_microsoft_graph_user?
    User.where(company_id: self.id).joins(:authentications).where("authentications.provider = ?", 'microsoft_graph').size > 0
  end

  def filter_account_enabled_users_in_microsoft_graph_sync?
    settings.sync_filters.dig(:microsoft_graph, :accountEnabled) == ['equals', true]
  end
end