module ExternalActivities
  module Yammer
    class Comment < Message
      def target_name
        "post"
      end
    end
  end
end
