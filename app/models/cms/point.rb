module Cms
  class Point < Base
    delegate :title, :icon, :body, :description, to: :data

    def image
      Cms::Image.new(self.data.image)
    end
  end
end
