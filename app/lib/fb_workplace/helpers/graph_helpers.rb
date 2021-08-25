module FbWorkplace::Helpers::GraphHelpers

  #alex: 317974978674016
  def loading(recipient_id)
    send_message(recipient_id, {sender_action: "typing_on"})
  end

  def carousel(recipient_id, elements = [])
    # https://developers.facebook.com/docs/messenger-platform/send-messages/template/generic/
    # elements = [{
    #               title: "Test1",
    #               image_url: "https://recognizeapp.com/assets/chrome/logo.png",
    #               buttons: [postback_button("button1", {action: "BadgeChoice", id: "123"}.to_json)]
    #             }
    # ]




    send_message(recipient_id, message: {attachment: {type: 'template', payload: {template_type: 'generic', elements: elements}}})
  end

  def quick_replies(recipient_id, message, elements = [])
    send_message(recipient_id, message: {text: message, quick_replies: elements})
  end


  def generate_carousel_badges(sendable_badges, post_id)
    fb_elements = []

    sendable_badges.each do |badge|
      fb_elements.push({
                         title: badge.short_name,
                         subtitle: badge.description,
                         image_url: badge.permalink,
                         buttons: [postback_button(I18n.t("dict.choose"), {action: "BadgeChoice", id: badge.id, post_id: post_id }.to_json)]
                       })
    end

    fb_elements
  end

  def generate_quick_reply_badges(sendable_badges, post_id)
    quick_reply_buttons = []

    sendable_badges.each do |badge|
      quick_reply_buttons.push quick_reply_button(badge.short_name, {action: "BadgeChoice", id: badge.id, post_id: post_id }.to_json, badge.permalink)
    end

    quick_reply_buttons
  end


  def quick_reply_button(title, payload, image)
    obj = {
      "content_type":"text",
      "title": title,
      "payload": payload,
    }

    if image.present?
      obj[:image_url] = image
    end

    return obj
  end

  def postback_button(text, payload)
    {
      type: 'postback',
      title: text,
      payload: payload
    }
  end

  def web_button(text, url)
    {
      "type":"web_url",
      "url": url,
      "title": text
    }
  end

  def webview_button(text, url)
    uri = URI.parse(url)
    uri.query = [uri.query, "viewer=fb_workplace"].compact.join('&')
    button = web_button(text, uri.to_s)
    button["webview_height_ratio"] = "full"
    button["messenger_extensions"] = true

    return button
  end

  def group_button(title, buttons)
    {
      "attachment":{
        "type":"template",
        "payload":{
          "template_type":"button",
          "text": title,
          "buttons": buttons
        }
      }
    }
  end

  #'/me/messenger_profile'
  def greeting(help_only: true)
    # NOTE: Greeting is set once for the entire bot. Which means the menu items are set once. 
    #       #default_url_params will always have network: "recognizeapp.com" when setting greeting
    #       since we'll likely use Recognize token to set the greeting. 
    #       This means that the bot menu buttons will always take user to /recognizeapp.com/<url>
    #       However, this happens to work out because of #ensure_correct_company in ApplicationController
    #       which will redirect to proper company path based on logged in user. 
    #       In the future, it might be better to use the /redirect/<url> paradigm, 
    #       to avoid latent bugs. We likely don't need direct SSO support since Webviews
    #       utilize silent login. 
    send_recognition_path = routes.new_chromeless_recognitions_path(default_url_params)
    open_app_path = routes.recognitions_path(default_url_params)

    help_cta = {
            'title': 'Help',
            'type':'postback',
            'payload': {action: "Help"}.to_json
    }

    if(help_only)
      call_to_actions = [help_cta]
    else
      call_to_actions = [
        webview_button('Send Recognition', get_wrapped_path(send_recognition_path)),
        webview_button('Open App', get_wrapped_path(open_app_path)),
        help_cta
      ]
    end

    {
      'greeting': [{
        'locale':'default',
        'text':"Hi {{user_first_name}}! Recognize is helping companies have great company culture through positive staff feedback and customized rewards."
      }],
      "get_started":{
        "payload": {action: "GetStarted"}.to_json
      },
      # 'whitelisted_domains': ['https://peterp.ngrok.io', 'https://recognizedev.ngrok.io', 'https://demo.recognizeapp.com','https://recognizeapp.com', 'https://work.facebook.com'],
      'whitelisted_domains': ["https://#{Rails.application.config.host}"],
      'persistent_menu':[{
        'locale':'default',
        'composer_input_disabled':false,
        'call_to_actions': call_to_actions
      }]
        # 'call_to_actions':[
        #   # {
        #   #   title: "My Account",
        #   #   type: "nested",
        #   #   call_to_actions: call_to_actions.map{|label, url| webview_button(label, url) }
        #   # },
        #   webview_button('Send Recognition', get_wrapped_path(send_recognition_path)),
        #   webview_button('Open App', get_wrapped_path(open_app_path)),
        #   # {
        #   #   'title': 'View Recognize',
        #   #   'type':'postback',
        #   #   'payload': {action: "ViewRecognize"}.to_json
        #   # },
        #   # {
        #   #   'title': 'Send Recognition',
        #   #   'type':'postback',
        #   #   'payload': {action: "SendRecognition"}.to_json
        #   # },
        #   {
        #     'title': 'Help',
        #     'type':'postback',
        #     'payload': {action: "Help"}.to_json
        #   },
        #   # {
        #   #   'title': 'Profile',
        #   #   'type':'postback',
        #   #   'payload': {action: "Profile"}.to_json            
        #   # }
        # ]}
      # ]
    }

  end

  def default_url_params
    {network: self.company.domain}
  end

  def get_post_id change_value
    (change_value.item == 'comment') ?
      change_value.comment_id : change_value.post_id
  end

  # get paths that go through the placeholder flow
  def get_wrapped_path(path)
    encoded_path = ERB::Util.url_encode(path)
    routes.fb_workplace_placeholder_url(default_url_params.merge(url: encoded_path, host: Rails.application.config.host, protocol: "https"))
  end

  def routes
    Rails.application.routes.url_helpers
  end
end
