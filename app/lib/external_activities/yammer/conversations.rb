module ExternalActivities
  module Yammer
    class Conversations
      def initialize
        @threads = Hash.new { |h,k| h[k] = [] }
      end

      def add(msg)
        @threads[msg.thread_id] << msg
      end

      def thread(thread_id)
        @threads.fetch(thread_id)
      end

      def thread_ids
        @threads.keys
      end

      def threads
        @threads.values
      end

      def self.init_from_messages(messages)
        conversations = self.new
        
        threads = Hash.new { |h,k| h[k] = [] } 
        messages.each { |msg| threads[msg.thread_id] << msg unless msg.system_message }

        threads.values.each do |msgs|
          entries = msgs.map do |msg|
            if msg.replied_to_id.nil?
              Yammer::Post.new_from_message(msg)
            else
              Yammer::Comment.new_from_message(msg)
            end
          end

          entries.sort_by!(&:created_at).reverse!
          0.upto(entries.length-1) do |x|
            x.upto(entries.length-1) do |y|
              if entries[x].replied_to_id == entries[y].id
                entries[x].receiver = entries[y].sender
                break
              end
            end
          end

          entries.each { |e| conversations.add(e) }
        end

        conversations
      end
    end
  end
end
