class MailStyler
  # NOTE: the interpolated variables must be an attribute on the CompanyCustomization model
  DEFAULT_STYLES = {
    email_header_logo_url: "%{email_header_logo_thumb_url}",
    email_header_logo_alt: "%{email_header_logo_alt_text}",
    header_text: "color: %{primary_text_color};",
    header_bg: "background: %{primary_bg_color};",
    body_bg: "background: %{secondary_bg_color};",
    text: "font-family: %{font_family}; color: %{secondary_text_color};",
    h1: "font-weight: 400;",
    h2: "font-size: 26px; line-height: 35px; font-weight: 200; margin: 0 0 25px 0;",
    h3: "font-size: 20px; line-height: 22px; font-weight: 400; margin: 20px 0;",
    h4: "font-weight: 200; margin: 0 0 10px 0; font-size: 18px;",
    h5: "font-weight: 400; margin: 0 0 10px 0; font-size: 16px;",
    p: "font-size: 16px; line-height: 18px; font-family: %{font_family}; margin: 0 0 15px 0;",
    warning_text: 'color: #dd6b55',
    warning_dot: 'padding: 5px; border-radius: 50%;background: #dd6b55;color: white;font-family: %{font_family};width: 10px;height: 10px;text-align: center;line-height: 12px;',
    clear: "<div style='clear: both; margin: -1px;height: 0;'></div>",

    button: "background-color:%{action_color};color:%{action_text_color};border:15px solid %{action_color};text-shadow:0 1px 0 rgba(136,136,136,0.71);font-size:15px;text-decoration:none;text-align:center;display:inline-block;font-family: %{font_family};line-height:15px;cursor:pointer;text-transform:none;margin:0 5px 15px 0;border-radius: 6px;",

    inline: "display:inline-block",

    a: "color: %{action_color}; text-decoration: underline;",

    hr: '<div style="height: 0px; border-top: 1px solid #d9dadd; border-bottom: 1px solid #fff;"></div>',

    hr_styles: "height: 0px; border-top: 1px solid #d9dadd; border-bottom: 1px solid #fff;",

    dllist: "text-align: center; margin: 0; float: left; margin-right: 7%;",

    dllistDD: "margin: 0; font-size: 50px; font-weight: 200;",

    dllistDT: "font-size:20px; font-weight: 200;",

    counter: "font-size:14px;line-height:14px;cursor:pointer;float:left;margin-right:10px;width:33px;height:12px;background-color:#6CC8FF;background-image:linear-gradient(top,#6CC8FF,#5CB8FF);color:#FFF!important;text-shadow:1px 1px 0 #3A97DE;text-decoration:none!important;box-shadow:inset 0 1px 0 rgba(28,85,184,0.52);border-radius:23px;text-align:center;padding:5px 0; text-shadow: none !important;",

    textSubtle: "color: #858585; font-size: 11px; line-height: 13px;",
    quote: "margin: 20px; padding:10px; font-style:italic; color: #858585; background-color: #f6f8fa",

    recognitionCard: "margin: 0 5%; width: 40%; min-width: 235px; float: left; position: relative; padding-bottom: 21px; margin-bottom: 20px;",

    title: "display: inline-block;",

    leaderboard: "list-style: none; margin: 0 auto 40px auto; max-width: 320px; padding: 0;",

    leaderboard_item: "padding: 10px; list-style: none; margin: 0;text-align: left;",

    table: "width: 100%; border-spacing: 0;",

    mail_border: "border: 1px solid #E7E7EA;",

    list: "list-style: none; padding: 0; margin: 0 0 10px 0;",
    gray: "color: gray;",
    margin0: "margin: 0;",

    label: 'display: block; color: #5F5F5F; font-size: 12px; margin-bottom: 5px;',
    header_banner: 'margin-bottom: 20px; background: #F7F7F7; padding: 10px 20px; border-radius: 10px;'
  }


  attr_reader :company, :interpolated_styles

  def initialize(company = nil)
    @company = company


    interpolate!
  end

  def custom_email_header_logo?
    styles(:email_header_logo_url) != CompanyCustomization.defaults[:email_header_logo_url]
  end

  def styles(*style_keys)
    @interpolated_styles.values_at(*style_keys).join(" ").html_safe
  end

  private

  def company_settings
    {
      font_family: company.customizations.font_family
    }
  end

  def interpolate!
    @interpolated_styles = {}
    DEFAULT_STYLES.inject(@interpolated_styles) do |map, (style_key, value)|
      style_overrides = (company&.customizations.present? ? company.customizations.all_attributes : CompanyCustomization.defaults.dup)
      style_overrides["font_family"] = company&.customizations&.font_family.presence || CompanyCustomization.defaults[:font_family]
      style_overrides["email_header_logo_thumb_url"] = company&.customizations&.email_header_logo_thumb_url.presence || CompanyCustomization.defaults[:email_header_logo_thumb_url]

      style_overrides = style_overrides.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo} # ensure symbols

      map[style_key] = (value.gsub('%;','##PERCENT##') % style_overrides).gsub('##PERCENT##', '%;')
      map
    end
    return @interpolated_styles
  end

end
