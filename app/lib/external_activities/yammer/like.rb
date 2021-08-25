module ExternalActivities
  module Yammer
    class Like
      include ActiveAttr::Model

      attribute(:id)
      attribute(:target_id)
      attribute(:target_name)
      attribute(:group_id)
      attribute(:company_id)
      attribute(:sender)
      attribute(:receiver)
      attribute(:metadata, default: lambda { {} })

      def self.build_likes(yammer_msg)
        user_ids = yammer_msg.liked_by.names.map(&:user_id)
        
        User.where(yammer_id: user_ids).map do |user|
          self.new(
            id: yammer_msg.id,
            target_id: yammer_msg.id,
            target_name: calc_target_name(yammer_msg),
            group_id: yammer_msg.group_id,
            sender: user,
            receiver: User.find_by(yammer_id: yammer_msg.sender_id),
            metadata: extract_metadata(yammer_msg)
          )
        end
      end

      def self.extract_metadata(msg)
        { id: msg.id,
          thread_id: msg.thread_id,
          sender_id: msg.sender_id,
          msg_created_at: msg.created_at,          
          body: msg.body.parsed }
      end

      def self.calc_target_name(msg)
        msg.replied_to_id.present? ? "comment" : "post"
      end
    end
  end
end
