module Cms
  class Tag < Base
    delegate :name, :id, to: :data
  end
end
