class ApplicationRecord < ActiveRecord::Base
  include DuplicateRequestPreventer::Base

  self.abstract_class = true
end
