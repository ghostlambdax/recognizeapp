module Cms
  class Image < Base
    delegate :alt, :url, to: :data

    def blank?
      data.blank?
    end
  end
end

