# frozen_string_literal: true

module DatatablesHelper
  def litatablify(datatable, endpoint:, daterange: true, nav_tabs: true, minimal_table_styles: false, namespace: datatable.namespace)
    render "layouts/litatable", datatable: datatable, endpoint: endpoint, namespace: namespace,
           daterange: daterange, show_nav_tabs: nav_tabs, minimal_table_styles: minimal_table_styles
  end

  def export_format_functions_js
    {
      removeLink: "return $(node).find('a').text();",
      nodeText: "return $(node).text();",
      formatSelect: "return window.R.utils.getSelectedLabelsFromSelect($(node)).join(', ');",
      formatStatusCol: "return $(node).text().replace(/\\(.*\\)/, '');",
      removeLinkKeepHref: "return $(node).find('a').prop('href')"
    }
  end

  def export_format_functions_rb
    {
      removeLink: proc { |str| Nokogiri::HTML.parse(str).css("a").text },
      nodeText: proc { |str| Nokogiri::HTML.parse(str).text },
      formatSelect: proc { |str| Nokogiri::HTML.parse(str).css('option[@selected="selected"]').map(&:text).join(', ') },
      formatStatusCol: proc { |str| Nokogiri::HTML.parse(str).text }, # I'm not really sure what this was originally built for
      removeLinkKeepHref: proc { |str| Nokogiri::HTML.parse(str).css("a").attr('href').value },
      nodeTextEmail: proc do |str|
        Nokogiri::HTML.fragment(str).children.map(&:text).detect { |text| text.strip.match(Constants::EMAIL_REGEX) }
      end,
      userPasswordResetLink: proc do |str|
        /data-user-id="(\d+)"/ =~ str
        user_id = $1
        user = User.find(user_id)
        user.reset_perishable_token!

        Rails.application.routes.url_helpers.edit_password_reset_url(
          user.perishable_token,
          host: Recognize::Application.config.host,
          protocol: 'https'
        )
      end
    }
  end
end
