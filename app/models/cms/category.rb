module Cms
  class Category < Base
    delegate :id, :description, :name, :slug, to: :data
  end
end
