module Cms
  class Post < Base
    delegate :slug, :title, :id, to: :data
    delegate :existing_link_url, :title, :link_on_features_page, :description, :date, :sections, :youtube_id, to: :acf
    delegate :integration_page_title, :integration_page_subtitle, :integration_name, :integration_description, :integration_use_cases, :what_youll_need, to: :acf
    delegate :product_update_title, :product_update_date, :product_update_description, to: :acf

    def image
      Cms::Image.new(acf.image)
    end

    def points
      return false unless acf.points

      Cms::Point.collection(acf.points)
    end

    def integration_logo
      Cms::Image.new(acf.integration_logo)
    end

    def product_update_image
      Cms::Image.new(acf.product_update_image)
    end
  end
end
