class FbWorkplace::Notifiers::BaseNotifier
  attr_reader :recognition, :company

  # public interface, meant to be called with DelayedJob
  def self.notify!(recognition_id)
    recognition = Recognition.find(recognition_id)
    factory(recognition).notify!
  end

  def self.factory(recognition)
    if recognition.is_anniversary?
      FbWorkplace::Notifiers::AnniversaryNotifier.new(recognition)
    else
      FbWorkplace::Notifiers::RecognitionNotifier.new(recognition)
    end
  end

  def initialize(recognition)
    @recognition = recognition
    @company = recognition.badge.company
  end

  def fb_client
    company.fb_workplace_client
  end

  def notify!
    recipients.each do |recipient|
      notify_recipient(recipient)
    end
  end

  def notify_recipient
    raise "must be implemented by subclass"
  end

  def recipients
    recognition.user_recipients
  end

  def permissible_buttons(*args)
    raise "Invalid share button specified: #{args}, must be within #{SHARE_BUTTONS}" unless (args - SHARE_BUTTONS).empty?

    permitted_btns = []
    permitted_btns << :view if args.include?(:view)
    permitted_btns << :share if args.include?(:share) && share_permitted?
    permitted_btns << :rewards if args.include?(:rewards) && can_show_rewards?
    permitted_btns
  end

  SHARE_BUTTONS = %i[view share rewards].freeze
  def share_buttons(*args)
    raise "Invalid share button specified: #{args}, must be within #{SHARE_BUTTONS}" unless (args - SHARE_BUTTONS).empty?

    # TODO: make https better
    uri = URI.parse(recognition.permalink)
    uri.scheme = 'https'
    permalink = uri.to_s

    permitted_buttons = permissible_buttons(*args)
    buttons = []

    if permitted_buttons.include?(:view)
      buttons << fb_client.webview_button(I18n.t('fb_workplace.view'), fb_client.get_wrapped_path(permalink))
    end

    if permitted_buttons.include?(:share) && share_permitted?
      buttons << fb_client.web_button(I18n.t('fb_workplace.share'), "https://work.facebook.com/sharer.php?display=page&u=#{permalink}")
    end

    if permitted_buttons.include?(:rewards)
      url = Rails.application.routes.url_helpers.redemptions_url(network: company.domain, host: Rails.application.config.host, protocol: 'https')
      wrapped_url = fb_client.get_wrapped_path(url)
      buttons += [fb_client.webview_button(I18n.t('fb_workplace.rewards'), wrapped_url)]
    end

    return buttons

  end  

  def share_permitted?
    !recognition.is_private?
  end

  def can_show_rewards?
    !company.hide_points? && company.allow_rewards? && recognition.earned_points.positive?
  end

  def format_message(message, user)
    if can_show_rewards?
      message += I18n.t('fb_workplace.check_rewards')
      message += I18n.t('user_notifier.points_from_recognition', points: recognition.earned_points, badge: recognition.badge.short_name) + "\n"
      message += I18n.t('user_notifier.points_available', points: user.redeemable_points)
    else
      message
    end
  end 
end
