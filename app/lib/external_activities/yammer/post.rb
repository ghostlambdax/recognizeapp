module ExternalActivities
  module Yammer
    class Post < Message

      def replied_to_id; nil end
      def receiver; nil end
      def target_name; nil end
      def target_id; nil end
    end
  end
end
