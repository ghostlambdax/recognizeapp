module RecognitionsHelper
  def workplace_share_link(recognition_link, opts)
    link_to I18n.t('fb_workplace.share_to_workplace'), workplace_share_helper(current_user.company, recognition_link), opts
  end

  def workplace_share_helper(company, recognition_link)
    url = company.settings.workplace_com_share_domain? ? 'my.workplace.com' : 'work.workplace.com'
    url = "https://#{url}/sharer.php?display=page&u=#{recognition_link}"
    return url.html_safe
  end

  def cache_key_for_stream_page
    "#{recognitions_cache_key}-stream"
  end

  def cache_key_for_res
    "#{recognitions_cache_key}-res"
  end

  def recognitions_cache_key
    count = current_user.company.recognitions.size
    max_updated_at = current_user.company.recognitions.maximum(:created_at).try(:utc).try(:to_s, :number)
    "#{current_user.company.domain}-#{current_user.id}-recognitions/all-#{count}-#{max_updated_at}-#{params[:page]}-#{@per_page_count}"
  end

  def message_label(setting = :message_is_required?)
    current_user.company.send(setting) ? t("dict.message") : "#{t('dict.message')} (#{t('dict.optional')})"
  end

  def tags_label
    suffix = current_user.company.requires_recognition_tags? ? "" : "(#{I18n.t("dict.optional")})"
    [current_user.company.custom_labels.recognition_tags_label.to_s, suffix.presence].compact.join(' ')
  end

  def tags_select2(form, tags = Tag.none, selected_tag_ids = nil)
    form.select :tag_ids,
                options_from_collection_for_select(tags, :id, :name, selected_tag_ids),
                {},
                {
                  placeholder: current_user.company.custom_labels.recognition_tags_label,
                  multiple: true,
                  class: "tags-select",
                  disabled: !current_user.company.recognition_tags_enabled?,
                  data: {
                    "is-ajax": true,
                    "ajax--url": "/tags",
                    "root-node": "tags",
                    "results-mapping": {
                      id: "id",
                      text: "name"
                    }
                  }
                }
  end

  def recipients_label(recognition, opts={})
    recognition.recipients.map do |recipient|
      if opts[:exclude_link] || recipient.deleted?
        recipient.label
      else
        link_to recipient.label, recipient
      end
    end.to_sentence.html_safe
  end

  def recipients_avatars(recognition)
    recognition.flattened_recipients.map do |recipient|
      recipient_avatar(recipient)
    end.flatten.join.html_safe
  end

  def recipient_avatar(user)
    # FIXME: this was just a quick hack to fix bug on prod
    if user.kind_of?(Team)
      link_to user.name, team_path(user)
    else
      link_to(image_tag(user.avatar_small_thumb_url, style: "height: 45px", alt: user.full_name, title: user.full_name, class: "avatar"), user_path(user)) + " "
    end
  end

  def recognition_approval_link(recognition, current_user, approvers_limit)
    # raw("<div class='plus_one'>"+link_to("", recognition_plus_ones_path(recognition), method: :post, remote: true, class: "plus_one_link")+"</div>")
    if recognition.approved_by?(current_user)
      link_to(like_counter(recognition), recognition_approval_path(recognition, recognition.approval_for(current_user), approvers_limit: approvers_limit), method: :delete, remote: true, class: "approval_link approved", data:{sender: recognition.sender.email, category: "recognition", event: "liked"})
    else
      # FIXME: what is the data: {sender: "..email.."} used for? This is suspect
      link_to(like_counter(recognition), recognition_approvals_path(recognition, approvers_limit: approvers_limit), method: :post, remote: true, class: "approval_link unapproved", data:{sender: recognition.sender_email, category: "recognition", event: "liked"})
    end
  end

  def recognition_approvers(recognition, limit=0)
    current_user_approval = recognition.approvals.detect { |a| a.giver_id == current_user.id } if current_user
    if !limit.nil? and limit > 0
      hover_max_limit = 20
      limit = limit -1 if current_user_approval
      approval_set = recognition.approvals[0..limit-1]
      ending = if recognition.approvals.size > limit
                 hover_approvals_list = recognition.approvals[limit..(limit+hover_max_limit-1)].map do |a|
                   content_tag(:li, link_to(a.giver.full_name, user_path(a.giver))) if current_user_approval != a
                 end.join
                 hover_approvals_list += content_tag(:li, content_tag(:div, link_to('more...', recognition_path(recognition)), class: 'more-approvers')) if recognition.approvals.count > limit + hover_max_limit
                 " <span class='moreValidationNames'>...<div class='approval-list'><ul>#{hover_approvals_list}</ul></div></span>"
               else
                 ""
               end
    else
      approval_set = recognition.approvals
      ending = ""
    end
    if current_user_approval
      your_link = link_to I18n.t("dict.you"), user_path(current_user)
      approval_set = approval_set.reject {|a| a.id == current_user_approval.id }
    end
    raw("<span id='recognition-approvers-#{recognition.id}'>"+
      approval_set.collect { |a|
        link_to a.giver.full_name, user_path(a.giver)
      }
      .unshift(your_link)
      .compact
      .join(", ")+
      ending+
      "</span>"
    )
  end

  def like_counter(recognition)
    if (recognition.approvals.size > 0)
      "+"+recognition.approvals.size.to_s
    else
      "+"
    end
  end

  def recognition_message(recognition, exclude_images: false, format: true)
    opts = {}.tap do |o|
      o[:tags_to_exclude] = ['img'] if exclude_images
      o[:escape_before_sanitizing] = true if recognition.input_format_text?
    end
    message = recognition.sanitized_message(**opts)
    # simple_format formats the message with paragraphs and new lines for legacy / plain-text recognitions
    message = simple_format(message, {}, sanitize: false) if recognition.input_format_text? && format
    message
  end

  # Edit page requires extra escaping, because the wysiwyg editor executes raw HTML tags.
  def recognition_message_for_edit_page(recognition)
    if wysiwyg_editor_shown?(recognition)
      if recognition.input_format_text?
        # escape manual raw text, format it (for the wysiwyg editor), and then mark as html_unsafe
        simple_format(CGI.escapeHTML(recognition.message)).to_str if recognition.message
      else
        recognition.sanitized_message(html_safe: false)
      end
    else
      # as-is (with implicit escaping)
      recognition.message
    end
  end

  def kiosk_mode_url
    opts = {}
    opts[:code] = @company.kiosk_mode_key if @company.kiosk_mode_key.present?
    opts[:network] = @company.domain
    opts[:dept] = nil
    opts[:animate] = true
    recognitions_grid_url(opts)
  end

  # NOTE: this is related to RecognitionsController#send_to_correct_start_action method
  def recognition_nomination_task_paths
    if page_id.include?("chromeless")
      r_path = new_chromeless_recognitions_path
      n_path = new_chromeless_nominations_path
      t_path = new_chromeless_task_submissions_path
    else
      r_path = new_recognition_path
      n_path = new_nomination_path
      t_path = new_task_submission_path
    end
    return [r_path, n_path, t_path]
  end

  def approve_recognition_button(recognition)
    endpoint = controller_path.include?('manager_admin') ?
                 approve_manager_admin_recognition_path(recognition) : approve_company_admin_recognition_path(recognition)
    recognition_message = message_for_approval_swal(recognition)
    link_to(I18n.t('dict.approve'),
      "javascript://",
      class: "button button-primary approve-button",
      data: {
        endpoint: endpoint,
        recognition_id: recognition.id,
        message: recognition_message,
        point_values: recognition.badge.point_values,
        sender: recognition.sender_name,
        recipients: recognition.recipients_label,
        badge_name: recognition.badge.short_name,
        badge_image: recognition.badge.permalink(50),
        input_format: recognition.input_format,
        request_form_id: SecureRandom.uuid
      }
    )
  end

  def deny_recognition_button(recognition)
    endpoint = controller_path.include?('manager_admin') ?
                 deny_manager_admin_recognition_path(recognition) : deny_company_admin_recognition_path(recognition)
    recognition_message = message_for_denial_swal(recognition)
    link_to(I18n.t('dict.deny'),
      "javascript://",
      class: "button deny-button",
      data: {
        endpoint: endpoint,
        recognition_id: recognition.id,
        message: recognition_message,
        sender: recognition.sender_name,
        recipients: recognition.recipients_label,
        badge_name: recognition.badge.short_name,
        badge_image: recognition.badge.permalink(50)
      }
    )
  end

  def status_label_for_datatable(recognition)
    if recognition.resolver_id == User.system_user.id
      return I18n.t('company_admin.recognitions.auto_approved')
    end

    recognition.status_label
  end

  def show_partial_name(recognition)
    filename = case
               when recognition.pending_approval?
                 'pending_approval'
               when recognition.denied?
                 'denied'
               else
                 'approved'
               end
    File.join('recognitions', 'show', filename)
  end

  def recipients_prefill_json(recipients)
    recipients.map do |u|
      next unless u.present?

      obj = {
        avatar_thumb_url: asset_path(u.avatar.small_thumb.url),
        type: 'User',
        name: u.full_name
      }

      if u.id.present?
        obj[:id] = u.id
      else
        obj[:email] = u.email
      end
      obj
    end.to_json.html_safe
  end

  def data_attrs_for_message_field(recognition = nil)
    atts = { event: "recognition-message", eventtype: "focused" }
    wysiwyg_editor_shown = current_user.company.recognition_wysiwyg_editor_enabled? || recognition&.input_format_html?
    atts[:errorElement] = ".trumbowyg-box" if wysiwyg_editor_shown
    atts
  end

  # Plain-text message additionally needs to be escaped twice for the approval swal (once if sanitized)
  # because the same message is rendered thrice - in the DOM (as data attr), in swal modal and in the WYSIWYG editor
  def message_for_approval_swal(recognition)
    message = if wysiwyg_editor_shown?(recognition)
                if recognition.input_format_text?
                  CGI.escapeHTML(recognition.message) if recognition.message
                else
                  recognition.sanitized_message(html_safe: false)
                end
              else # plaintext editor
                recognition.message
              end
    CGI.escapeHTML(message) if message
  end

  # The message additionally needs to be escaped once for the denial swal (unless sanitized)
  # because the same message is rendered twice - in the DOM (as data attr) and in swal modal
  def message_for_denial_swal(recognition)
    if recognition.input_format_html?
      recognition.sanitized_message(html_safe: false)
    else
      CGI.escapeHTML(recognition.message) if recognition.message
    end
  end

  # Note: This is a convenience method only. The actual logic for this resides in frontend.
  #       (see lib/Post.js and company_admin/recognitions/index.js)
  def wysiwyg_editor_shown?(recognition)
    company = recognition.authoritative_company || @company
    recognition.input_format_html? || company.recognition_wysiwyg_editor_enabled?
  end
end
