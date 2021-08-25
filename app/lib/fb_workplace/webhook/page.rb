class FbWorkplace::Webhook::Page < FbWorkplace::Webhook::Base
  # This is the main entry point when the bot is tagged (or 'mentioned')
  #
  class Mention < FbWorkplace::Webhook::Change
    def start_message
      I18n.t('fb_workplace.sign_up_first_time')
    end

    def fb_client
      @fb_client ||= (company.try(:fb_workplace_client) || unclaimed_token.try(:fb_workplace_client))
    end

    # post id: 180340515846894_180617165819229

    #<FbWorkplace::Webhook::Page::Mention:0x007fcb9ce98a80 @data=#<Hashie::Mash field="mention" value=#<Hashie::Mash community=#<Hashie::Mash id="627102830783995"> created_time=1506819629 item="post" message="Recognize" message_tags=#<Hashie::Array [#<Hashie::Mash id="1714217182220546" length=9 name="Recognize" offset=0 type="page">]> post_id="180340515846894_180370749177204" sender_id="317974978674016" sender_name="Alex Grande" verb="add">>, @webhook=#<FbWorkplace::Webhook::Page:0x007fcb9ce7b1b0 @payload=#<Hashie::Mash entry=#<Hashie::Array [#<Hashie::Mash changes=#<Hashie::Array [#<Hashie::Mash field="mention" value=#<Hashie::Mash community=#<Hashie::Mash id="627102830783995"> created_time=1506819629 item="post" message="Recognize" message_tags=#<Hashie::Array [#<Hashie::Mash id="1714217182220546" length=9 name="Recognize" offset=0 type="page">]> post_id="180340515846894_180370749177204" sender_id="317974978674016" sender_name="Alex Grande" verb="add">>]> id="1714217182220546" time=1506819631>]> object="page">>>
    def call
      action_or_signup(:show_carousel, {fb_workplace_post_id: self.value.post_id})
    end

    def self.show_carousel(arguments)
      community_id = arguments[:fb_workplace_community_id]
      sender_id = arguments[:fb_workplace_sender_id]
      post_id = arguments[:fb_workplace_post_id]

      data = Hashie::Mash.new(value: {community: {id: community_id}, post_id: post_id, sender_id: sender_id})

      m = FbWorkplace::Webhook::Page::Mention.new(data, {})
      #user = m.get_recognize_user(sender_id)
      m.show_carousel
    end

    # Get data from post and 
    # massage recipient payload from Workplace to be proper
    # application user objects
    def get_post_data(post_id)
      post_data = fb_client.get_post(post_id)
      recipients = post_data[:recipients]
  
      if recipients.present?
        user_recipients = recipients.map do |r|
          recognize_user = get_recognize_user(r.id) || init_recognize_user(r.id)
        end
        post_data[:recipients] = user_recipients
      end
      return post_data
    end 

    # TODO: rename to something like finish_recognition
    def show_carousel
      message = I18n.t("fb_workplace.choose_a_badge")
      sender = get_recognize_user(self.sender_id)
      id_to_post_to = self.comment_id || self.post_id
      post_data = self.get_post_data(id_to_post_to)
      recipients = post_data[:recipients]

      url_payload = {fb_workplace_post_id: id_to_post_to,
                 badge_list_open: true,
                 protocol: "https",
                 network: sender.network,
                 show_form: 'recognition',
                 dept: nil,
                 message: post_data[:message],
                 host: Rails.application.config.host}

      if recipients.present?
        url_payload[:recipients] = recipients.map(&:recognize_hashid).join(",")
        url_payload[:recipient_network] = sender.network
      end

      instructions = I18n.t("fb_workplace.finish_recognition_instructions")

      url = Rails.application.routes.url_helpers.new_chromeless_recognitions_path(url_payload)
      url = fb_client.get_wrapped_path(url)
      fb_client.send_message(sender_id, message: fb_client.group_button(instructions, [fb_client.webview_button(message, url)]))
    end
    
  end

  class GetStarted < FbWorkplace::Webhook::Message

    def self.welcome(arguments)
      community_id = arguments[:fb_workplace_community_id]
      sender_id = arguments[:fb_workplace_sender_id]
      post_id = arguments[:fb_workplace_post_id]

      # This is the correct syntax. There are other places that may be wrong
      data = Hashie::Mash.new(sender: {id: sender_id, community: {id: community_id}})

      new(data, {}).welcome_for_first_time
    end

    def start_message
      "Connect Recognize to your Workplace by Facebook to get started."
    end

    def call
      action_or_signup(:welcome, {})
    end

    def welcome
      fb_client.send_message(self.sender_id, message: {text: "Recognize is connected to your Workplace by Facebook. To recognize someone, open the bot menu (3 horizontal lines in the text box), and select \"Send Recognition\". Write *help* if you need anything or go to https://recognizeapp.com/help"})
    end

  end

  class ResetAccountConnection < FbWorkplace::Webhook::Message
    def call
      message = _('Your account connection has been cleared. Type \'Connect\' if you would like to reconnect ')
      sender.update_column(:fb_workplace_id, nil)
      fb_client.send_message(self.sender_id, message: {text: message}.to_json)
    end
  end
  class ViewRecognize < FbWorkplace::Webhook::Message

    def call
      action_or_signup(:view_recognize, {})
    end

    def start_message
      "Connect Recognize to view employee recognition and rewards."
    end

    def view_recognize
      url = Rails.application.routes.url_helpers.stream_url(network: sender.network, dept: nil, host: Rails.application.config.host)

      message = "Click the link to view the Recognize portal to see your profile, rewards, and more."
      buttons = [fb_client.web_button("View Recognize", url)]

      fb_client.send_message(self.sender_id, message: fb_client.group_button(message, buttons))
    end

  end

  class SendRecognition < FbWorkplace::Webhook::Message

    def call
      action_or_signup(:send_recognition, {})
    end

    def start_message
      "To send recognition, you need to connect Recognize to your Workplace by Facebook."
    end

    def send_recognition
      url = Rails.application.routes.url_helpers.new_recognition_url(network: sender.network, dept: nil, host: Rails.application.config.host)
      message = "Click the link to view the send recognition form."
      message += "You can send a recognition from here too. Type help to learn how." if sender.company.allow_nominations?

      buttons = [fb_client.web_button("Send Recognition", url)]

      fb_client.send_message(self.sender_id, message: fb_client.group_button(message, buttons))
    end

  end

  class Help < FbWorkplace::Webhook::Message

    def call
      help
    end

  end

  class Profile < FbWorkplace::Webhook::Message

    def call
      show_link(which: :profile)
    end

  end

  class Text < FbWorkplace::Webhook::Message

    def call
      text = self.data.message.text.try(:downcase)

      case text
      when "get started"
        show_link(which: :get_started)
      when "reset"
        show_link(which: :reset)
      when "help", "hi", "hello", "what can you do", "what", "wtf"
        help
      when "rewards", "profile", "admin", "manage", "connect", "reconnect"
        show_link(which: text.to_sym)
      when "recognize", "recognise", "send recognition", "r"
        show_link(which: text.to_sym)
      # when "dashboard", "customize badges", "top employees", "manage rewards", "change settings"
      #   show_link(which: text.to_sym)
      else
        dont_know
      end
    end

    def dont_know
      message = "Recognize can\'t respond to that yet. Try recognizing someone by opening the bot menu (3 horizontal lines in the text box), and select \"Send Recognition\""
      fb_client.send_message(self.sender_id, message: {text: message})
      # fb_client.send_image_message(self.sender_id, 'https://media.giphy.com/media/VKtsOAHDx1Luo/giphy.gif')
    end

    def self.show_link(arguments)
      community_id = arguments[:fb_workplace_community_id]
      sender_id = arguments[:fb_workplace_sender_id]
      post_id = arguments[:fb_workplace_post_id]
      which = arguments[:which]

      data = Hashie::Mash.new(value: {community: {id: community_id}, post_id: post_id, sender_id: sender_id})
      data.message = Hashie::Mash.new(text: which)

      # t = FbWorkplace::Webhook::Page::Text.new(data, {})
      # t.show_link("Nice work! Your account is connected.")
      GetStarted.welcome(arguments)
    end
  end

  class TryAgainToRecognize < FbWorkplace::Webhook::Message
    def call
      post_id = JSON.parse(self.data.message.quick_reply.payload)["post_id"]
      action_or_signup(:show_carousel, {fb_workplace_post_id: post_id})
    end

    def show_carousel
      post_id = JSON.parse(self.data.message.quick_reply.payload)["post_id"]

      message = message.present? ? message + " " + I18n.t("fb_workplace.choose_a_badge") : I18n.t("fb_workplace.choose_a_badge")

      if user_ids(post_id).present?
        user = get_recognize_user(self.sender_id)

        badges = fb_client.generate_quick_reply_badges(user.sendable_recognition_badges, post_id)
        fb_client.quick_replies(self.sender_id, message, badges)
      else
        fb_client.send_message(self.sender_id, message: {text: "To send a recognition, tag at least one other person. Try writing another post and *tag both @Recognize and a colleague*."})
      end
    end

    def user_ids(post_id)
      post_data = fb_client.get("/#{post_id}", {"fields": "message,message_tags"})
      message_tags = post_data.message_tags
      return message_tags.select{|m| m.type == "user"}.map(&:id)
    end
  end
end
