# frozen_string_literal: true

# {"object"=>"link", "entry"=>[{"id"=>"1178052929022313", "time"=>1556835427, "changes"=>[{"value"=>{"link"=>"https://recognizedev.ngrok.io/recognitions/efpit4c", "community"=>{"id"=>"627102830783995"}, "user"=>{"id"=>"321093481697660"}}, "field"=>"preview"}]}]}
class FbWorkplace::Webhook::Link < FbWorkplace::Webhook::Base
  class Preview < FbWorkplace::Webhook::Change
    # Assumption for now: this is only rendering recognitions
    # Need to refactor if rendering other types

    delegate :sender, :sender_name, to: :recognition

    def call
      return if self.recognition.blank?

      result = {
        status: 200,
        headers: {"Content-Type" => "application/json"},
      }

      result[:payload] = compile_payload
      result[:payload] = Array(result[:payload])
      result
    end

    def link
      self.value.link
    end

    def additional_data
      # We pass the sender name as label override
      # because it has logic to show company name
      # when its an anniversary recognition
      from = user_payload("From", sender, sender_name)
      sent_at = date_payload(_("Sent"), recognition.created_at.iso8601)
      data = [from]

      self.recognition.user_recipients[0..5].each do |recipient|
        data << user_payload("To", recipient)
      end
      data << sent_at
      data
    end

    def compile_payload
      {
        "data": [
          {
            "link": self.link,
            "title": self.recognition.badge.short_name,
            "description": self.title,
            "privacy": "organization",
            "type": "link",
            "icon": self.recognition.badge.permalink(50),
            "additional_data": additional_data
          }
        ],
        "linked_user": true
      }.to_json
    end

    def recognition
      @recognition ||= begin
        uri = URI.parse(link)
        slug = uri.path.split("/").last
        Recognition.where(slug: slug).first
      end
    end

    def date_payload(title, date)
      {
        "title": title,
        "format": "datetime",
        "value": date.to_time
      }
    end

    def user_payload(title, user, label = nil)
      if user.fb_workplace_id.present?
        format = "user"
        value = user.fb_workplace_id
      else
        format = "text"
        value = label || user.full_name
      end

      {
       "title": title,
       "format": format,
       "value": value
      }
    end

    def title
      recognition.message
    end

    def request_time
      Time.zone.at(self.entry.time)
    end
  end
end
