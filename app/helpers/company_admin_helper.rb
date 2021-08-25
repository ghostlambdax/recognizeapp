module CompanyAdminHelper
  def company_admin_sidebar_link(title, path, opts={})
    uri = URI.parse(path)
    tag_opts = {}
    tag_opts[:class] = "active" if current_page?(path)
    tag_opts[:data] = opts[:data]
    hquery = ActiveSupport::HashWithIndifferentAccess.new(CGI::parse(uri.query || ""))
    hquery[:dept] = params[:dept] unless hquery[:dept].present? || opts[:dept].nil?
    uri.query = URI.encode_www_form(hquery)

    link = link_to(uri.to_s) do
      get_admin_link_text(title, opts)
    end

    content_tag(:li, link, tag_opts)
  end

  def company_admin_tertiary_sidebar_link(title, path, matching_paths, opts = {})

    tag_opts = {}
    tag_opts[:data] = opts[:data]
    tag_opts[:class] = 'active' if active_subnav?(matching_paths)

    content_tag(:li, tag_opts) do
      link_to(path) do
        get_admin_link_text(title, opts)
      end
    end
  end

  def tertiary_nav_link(label, path, opts = {})
    content_tag(:li, class: ('active' if current_page?(path))) do
      link_to label, path, class: opts[:class]
    end
  end

  def active_subnav?(matching_paths)
    matching_paths = Array(matching_paths)
    matching_paths.any? do |possible_path|
      request.url.match?(possible_path)
    end
  end

  private

  def get_admin_link_text(title, opts)
    if opts[:icon].present?
      feather_icon(opts[:icon], height: 15) + title
    else
      title
    end
  end
end
