module NominationsHelper

  def quick_nomination_select2(recognition_recipient)
    user = recognition_recipient.user
    recognition = recognition_recipient.recognition
    company = recognition.authoritative_company

    # No need to check Nomination#badge_awardable because we still want to show the select2
    # no matter what. User will receive sweet alert if there is an error nominating them
    if !Nomination.globally_awardable?(user)
      content_tag(:span) { "Last awarded: #{l(user.last_nomination_awarded_at, format: :slash_date)}" }
    else
      badges = company.company_badges.quick_nominations 
      options = badges.map{|b| 
        tag_opts = {
          value: b.id,
          selected: recognition_recipient.reference_recipient_nominated_badge_ids.try(:include?, b.id),
          disabled: !Nomination.badge_awardable?(user, b),
          locked: "locked",
          data: {
            last_awarded: company.user_last_awarded_badge_at(user, b),
            image_path: b.permalink(50)
          }
        }
        content_tag(:option, tag_opts) do
          b.short_name
        end
      }

      if options.present?
        select_tag "badge", options.join.html_safe, 
          include_blank: "Select a badge", 
          multiple: true,
          data: {end_point: nominations_path(network: user.network), recipient_id: user.id}, 
          class: "quick-nomination"
      else
        "<div rel='tooltip' title='There are no badges able to be nominated'></div>".html_safe
      end
    end
  end

  def link_to_award_nomination(nomination)
    recipient = nomination.recipient
    if !Nomination.globally_awardable?(recipient) || !Nomination.badge_awardable?(recipient, nomination.badge)
      "Last awarded: #{l(recipient.last_nomination_awarded_at, format: :slash_date)}"      
    else
      award_text = nomination.is_awarded? ? t("nominations.awarded") : t("nominations.award")
      awarded_css_classes = "nomination-status button form-loading-ignore"
      awarded_css_classes << " button-success" if nomination.is_awarded?
      link_to award_text, award_company_admin_nomination_path(nomination), remote: true, method: :post, class: awarded_css_classes
    end
  end

end
