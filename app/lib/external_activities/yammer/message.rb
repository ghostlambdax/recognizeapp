module ExternalActivities
  module Yammer
    class Message
      include ActiveAttr::Model

      attribute(:id)
      attribute(:thread_id)
      attribute(:group_id)
      attribute(:replied_to_id)
      attribute(:target_id)
      attribute(:company_id)
      attribute(:sender_id)
      attribute(:sender)
      attribute(:receiver)
      attribute(:likes, default: lambda { [] })
      attribute(:body, default: lambda { "" })
      attribute(:created_at)
      attribute(:metadata, default: lambda { {} })

      def inspect
        "{id: #{id}, thread_id: #{thread_id}, body: #{body}}"
      end

      def self.new_from_message(msg)
        self.new.tap do |p|
          p.id = msg.id
          p.thread_id = msg.thread_id
          p.group_id = msg.group_id
          p.replied_to_id = msg.replied_to_id
          p.target_id = msg.replied_to_id
          p.sender_id = msg.sender_id
          p.sender = User.find_by(yammer_id: msg.sender_id)
          p.likes = Yammer::Like.build_likes(msg)
          p.body = msg.body.parsed
          p.created_at = Time.parse(msg.created_at)
          p.metadata = extract_metadata(msg)
        end
      end

      def self.extract_metadata(msg)
        { id: msg.id,
          thread_id: msg.thread_id,
          sender_id: msg.sender_id,
          replied_to_id: msg.replied_to_id,
          created_at: msg.created_at,
          body: msg.body.parsed }
      end
      private_class_method(:extract_metadata)
    end
  end
end
