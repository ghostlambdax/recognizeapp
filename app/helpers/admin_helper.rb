module AdminHelper
  def admin_company_subscription_link
    if @company.subscription.present?
      label =  "Edit subscription"
      url = edit_admin_company_subscription_path(@company, @company.subscription)
    else
      label = "Create subscription"
      url = new_admin_company_subscription_path(@company)
    end

    link_to label, url, class: "button button-primary button-small"
  end

  def options_for_packages(company)
    options = Subscription.all_packages
      .map { |key, value| [value.to_s.humanize, key]}
    selected_option = company.price_package.nil? ? "null": company.price_package
    options_for_select(options, selected_option)
  end

  def options_for_sync_frequency
    CompanySetting.sync_frequencies.keys.map { |type| [type.capitalize, type] }
  end
end