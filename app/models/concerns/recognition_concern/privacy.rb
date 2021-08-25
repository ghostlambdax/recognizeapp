# Recognition privacy flags
# @is_public_to_world - true - public to world, do not need to be logged in to see recognition
# @is_public_to_world - false - public to company, need to be logged in to see recognition, everyone in company can see recognition
# @is_private - true - only the sender, recipients, and admins can see recognition
# NOTE: @is_public_to_world(true) is mutually exclusive to @is_private(true)
#       @is_public_to_world(false), can have either @is_private(true|false)
module RecognitionConcern
  module Privacy
    extend ActiveSupport::Concern

    def toggle_privacy_between_company_and_world!
      if self.is_public_to_world
        # we can always make it private
        update_attribute :is_public_to_world, false
      else
        # however, company global privacy flag must be off to make public
        if self.authoritative_company.allows_public_recognitions?
          update_attribute :is_public_to_world, true
        end
      end
    end

    def make_public!
      update_attribute :is_public_to_world, true if self.authoritative_company.allows_public_recognitions?
    end

    protected

    def set_privacy
      if self.badge&.force_private_recognition?
        self.is_private = true
        self.post_to_yammer_wall = self.post_to_fb_workplace = false
      end

      self.is_public_to_world = !self.is_private && self.authoritative_company&.allows_public_recognitions? # public to the world

      return true
    end
  end
end
