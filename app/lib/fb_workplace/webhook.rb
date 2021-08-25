class FbWorkplace::Webhook

  def self.factory(params, request_uuid: )
    return case params["object"]
    when "page"
      FbWorkplace::Webhook::Page.new(params, request_uuid: request_uuid)
    when "application"
      FbWorkplace::Webhook::Application.new(params, request_uuid: request_uuid)
    when "link"
      FbWorkplace::Webhook::Link.new(params, request_uuid: request_uuid)
    else
      nil
    end
  end

  class Data
    include FbWorkplace::Helpers::BotHelpers
    attr_reader :data, :webhook, :entry, :opts

    def initialize(data, webhook, opts = {})
      @data = data
      @webhook = webhook
      @opts = opts
      @entry = opts[:entry]
    end

    def community_id
      raise "Not implemented - must be implemented by subclasses"
    end

    def fb_client
      raise "Not implemented - must be implemented by subclasses"
    end

    def get_recognize_user(fb_workplace_id, remote_lookup: true)
      return nil if fb_workplace_id.blank?
      user = User.where(fb_workplace_id: fb_workplace_id).first

      if user.present?
        return user
      end

      return nil if fb_client.blank?

      if remote_lookup
        log "FbWorkplace::Webhook - Getting user from remote lookup"
        fb_sender = fb_client.user(fb_workplace_id)
        unless fb_sender["email"].nil?
          sender_in_recognize = User.where(network: company.domain, email: fb_sender["email"]).first
          sender_in_recognize.update_columns(fb_workplace_id: fb_workplace_id) if company.settings.autolink_fb_workplace_accounts?
          User.delay(queue: 'priority').sync_fb_workplace_data(sender_in_recognize.id) if sender_in_recognize.present?
          return  sender_in_recognize
        else
          log "FbWorkplace::Webhook - Got blank user email, returning nil"
          return nil
        end
      else
        log "FbWorkplace::Webhook - Do not get user from remote_lookup, return nil"
        return nil
      end

    rescue => e
      log "Caught exception: #{e.message}"
      log "During Webhook#get_recognize_user(#{fb_workplace_id})"
      log e
      return nil
    end

    # this has a sister method in
    # app/models/concerns/fb_workplace_user_concern.rb#sync_fb_workplace_data
    def init_recognize_user(sender_id)
      return nil if sender_id.blank?
      fb_user = fb_client.user(sender_id)
      if fb_user.present? && fb_user.email.present?
        u = User.new(
          company_id: self.company.id,
          email: fb_user.email,
          fb_workplace_id: fb_user.id,
          first_name: fb_user.first_name,
          last_name: fb_user.last_name,
          job_title: fb_user.title)
        u.skip_same_domain_check = true
      else
        Rails.logger.info "There was a problem properly trying to sync workplace user"
        Rails.logger.info "#{u.fb_workplace_id} => #{fb_user.inspect}"
        u = User.new
      end
      return u
    end

    def company
      # @company ||= Company.find_by_fb_workplace_community_id(self.community_id)
      @company ||= determine_company
    end

    def determine_company
      # Companies may share an installation
      authoritative_company = Company.find_by_fb_workplace_community_id(self.community_id)

      # So, if the company is in a family, we need to select the correct one
      if authoritative_company.try(:in_family?)
        # match on email domain of fb sender
        fb_user = authoritative_company.fb_workplace_client.user(sender_id)
        recognize_user = User.where(fb_workplace_id: fb_user.id)&.first
        if recognize_user
          recognize_user&.company
        else
          # if there is no recognize user at this point
          # it means the current user hasn't connected their account
          # and we need to figure out which company to reference when mulitple
          # recognize companies share a workplace installation.
          # NOTE: this logic may need to be tweaked
          authoritative_company
        end

      else
        return authoritative_company
      end
    end

    def sender
      get_recognize_user(self.sender_id)
    end

    def acceptable?
      acceptable_request_time?(request_time)
    end

    WINDOW = 20 # in seconds
    def acceptable_request_time?(request_time)
      window = Recognize::Application.config.rCreds['fb_workplace']['request_window'] || WINDOW
      request_time.between?(WINDOW.seconds.ago, window.seconds.from_now)
    end

    def unclaimed_token
      FbWorkplaceUnclaimedToken.where(community_id: community_id).last
    end

    def log(msg)
      webhook.log(msg)
    end
  end

  class Entry < Data
    delegate :id, :time, to: :data

    def changes
      if data.changes.present?
        data.changes.map{|c| Change.factory(c, self, webhook) }
      else
        []
      end

    end

    def messages
      if data.messaging.present?
        data.messaging.map{|m| Message.factory(m, self, webhook) }
      else
        []
      end
    end

  end

  class Change < Data
    delegate :field, :value, to: :data
    delegate :sender_id, :post_id, :comment_id, to: :value

    # delegate the change to a class within a type of webhook
    # eg. FbWorkplace::Webhook::Page::Mention
    def self.factory(data, entry, webhook)
      (webhook.class.to_s+"::"+data.field.classify).constantize.new(data, webhook, entry: entry)
    end

    def community_id
      value.community.id
    end

    def fb_workplace_sender
      @fb_workplace_sender ||= self.value.from
    end

    def sender_id
      unless self.fb_workplace_sender.present?
        return value.sender_id
      end
      self.fb_workplace_sender.id
    end

    def request_time
      # time via mentions is in seconds
      # whereas time via messages is in milliseconds
      # and is also a different attributes
      Time.at(self.value.created_time)
    end

  end


  class Message < Data
    def self.factory(data, entry, webhook)
      payload = self.payload(data)
      (webhook.class.to_s+"::"+payload['action']).constantize.new(data, webhook, entry: entry, payload: payload)
    end

    def self.payload(data)
      if data.postback.present? && data.postback["payload"].present?
        p = data.postback.payload
      elsif data.message
        if data.message["quick_reply"]
          p = data.message.quick_reply.payload
        else
          p = {action: "Text", text: data.message.text}.to_json
        end
      end

      JSON.parse(p)
    end

    def community_id
      self.data.sender.community.id
    end

    def payload
      @payload ||= begin
        pyl = opts[:payload] || self.class.payload(self.data)
        Hashie::Mash.new(pyl)
     end
    end

    def fb_client
      company.try(:fb_workplace_client) || unclaimed_token.try(:fb_workplace_client)
    end

    def fb_workplace_sender
      @fb_workplace_sender ||= self.data.sender
    end

    def sender_id
      fb_workplace_sender.id
    end

    def sender
      @sender ||= begin
        remote_lookup = company.settings.autolink_fb_workplace_accounts?
        get_recognize_user(self.sender_id, remote_lookup: remote_lookup)
      end
    end

    def request_time
      # time via mentions is in seconds
      # whereas time via messages is in milliseconds
      # and is also a different attributes
      Time.at(self.data.timestamp / 1000)

    end

    def start_message
      "Before we start talking, let's connect your Recognize account with your Workplace account. If you don't yet have a Recognize account, don't worry, you can create one. \n\nIf you would like to reconnect to a different Recognize account, make sure to log out of recognizeapp.com."
    end

  end

  # This is an adapter meant to be used by other parts of the app
  # outside of the context of a proper webhook
  # so other parts can send similar messages like 'show_link_to_join_user_account'
  # and keep similar code together
  class EasyMessage < Message
    attr_reader :company, :community_id, :sender_id

    def initialize(company, community_id, sender_id)
      @company = company
      @community_id = community_id
      @sender_id = sender_id
    end

    def fb_workplace_sender
      Hashie::Mash.new({id: sender_id})
    end

    def self.welcome_for_first_time(arguments)
      FbWorkplace::Webhook::Page::GetStarted.welcome(arguments)
    end
  end
end
