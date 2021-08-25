module Api
  module V2
    module Entities
      class ValidationError < ErrorResponse
        def errors
          record = self.exception.record
          record.consolidate_errors if record.respond_to?(:consolidate_errors)
          errors = record.errors
          map = {}
          errors.messages.each do |attr, messages|
            map[attr] ||= []
            messages.each do |msg|
              map[attr] = if msg.respond_to?(:starts_with?) && msg.starts_with?("^")
                msg.gsub(/^\^/,'')
              else
                errors.full_message(attr, msg)
              end
            end
          end
          map
        end
      end
    end
  end
end


# module Api
#   module V2
#     module Entities
#       class ValidationError < ErrorResponse
#         def errors
#           errors = self.exception.record.errors
#           map = {}
#           errors.messages.each do |attr, messages|
#             map[attr] ||= []
#             messages.each do |msg|
#               if msg.starts_with?("^")
#               else
#                 map[attr] << errors.full_message
#               end
#             end
#             # map[attr] = errors.full_messages_for(attr)
#           end
#           map
#         end
#       end   
#     end
#   end
# end
