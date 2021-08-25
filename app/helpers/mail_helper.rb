module MailHelper

  def company_styler(company)
    MailStyler.new(company)
  end

  def mail_styler
    @mail_styler ||= MailStyler.new
  end

  def mail_styles(*styles)
    mail_styler.styles(*styles)
  end

  # campaign is the name of the email
  # campaign_type is what type of email(eg Blast, Notifier, Reminder)
  def generate_mixpanel_email(user, campaign, campaign_type, custom_opts={})
    
    mixpanel_data = {
      event: "User opened #{campaign_type}",
      properties: {
        distinct_id: user.email,
        # TODO: change this below logic to check network when we implement xcompany
        token: user.company_id == 1 ? "f6226718dca5c61a2ce1b3d6925ce6b5" : "26747720351902ef3610eb96971f064e",
        time: Time.now.to_i,
        campaign_type: campaign_type,
        campaign: campaign
      }
    }.merge(custom_opts)

    data = Base64.encode64(mixpanel_data.to_json)
    
    return "<img src='http://api.mixpanel.com/track/?data=#{data}&ip=1&img=1' />".html_safe
  end

  def from_header_for_user(user)
    "#{user.full_name} <donotreply@recognizeapp.com>"
  end

  def birthday_privacy_label(user)
    user.receive_birthday_recognitions_privately? ? t("notifier.private") : t("notifier.public")
  end

  def anniversary_privacy_label(user)
    user.receive_anniversary_recognitions_privately? ? t("notifier.private") : t("notifier.public")
  end

  ### Recognition WYSIWYG helpers: BEGIN ###
  def recognition_message_for_mail(recognition)
    if recognition.message_plain.present?
      recognition.message_plain
    elsif recognition.input_format_html?
      message = recognition.sanitized_message
      message = I18n.t('dict.image')  if message.include? 'img'
      message
    else
      # Note: html-escaping happens implicitly here, as this string is not marked as html_safe, unlike above case
      recognition.message
    end
  end

  # This conversion is being done for emails because of the difficulty in controlling image dimensions and possible security concerns
  # (Github does something similar too)
  def convert_image_tags_to_link_tags(html)
    return html unless html.include? 'img'

    image_label = I18n.t('dict.image')
    # regex approach
    html.gsub(/<img [^<>]*src="(\S+?)"[^<>]*>/, %(<a href="\\1">#{image_label}</a>)).html_safe

    # nokogiri approach: this is more robust and way more flexible, but ~100x slower
    # doc = Nokogiri::HTML.fragment(html)
    # doc.css('img').each{|e| n = doc.document.create_element('a', image_label); n['href'] = e['src']; e.replace(n) }
    # doc.to_s.html_safe
  end
  ### Recognition WYSIWYG helpers: END ###

  ### IntervalNotificationRunner: Dry run helpers: BEGIN ###
  def format_dry_run_time(time)
    "#{time.to_s(:long)} (#{time.zone})"
  end

  def company_count_info_for_dry_run(company_count, company_with_result_count)
    company_info = "Company count: #{company_count} eligible #{'company'.pluralize(company_count)}"
    yield_info = if company_count > 1
                   if company_with_result_count.zero?
                     " (none yielded result)"
                   elsif company_with_result_count == company_count
                     " (all yielded result)"
                   else
                     ", #{company_with_result_count} of which yielded result"
                   end
                 end
    "#{company_info}#{yield_info}"
  end

  def run_count_info_for_forecast(total_count, matching_count)
    total_run_info = "Run count: #{total_count} total #{'run'.pluralize(total_count)}"
    matching_run_info = if total_count > 1
                          if matching_count.zero?
                            ", none of which had any matching company"
                          elsif matching_count == total_count
                            ", all of which had matching companies"
                          else
                            ", #{matching_count} of which had matching companies"
                          end
                        end
    "#{total_run_info}#{matching_run_info}"
  end
  ### IntervalNotificationRunner: Dry run helpers: END ###

end
