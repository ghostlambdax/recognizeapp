module Cms
  class Base
    include Rails.application.routes.url_helpers

    attr_reader :data

    delegate :acf, to: :data

    def self.wp_client
      @wp_client ||= Recognize::Application.config.wp_client
    end

    def self.collection(items)
      items.map{|item| self.new(item) }
    end

    def initialize(data)
      @data = data || {}
    end

    def present?
      data.present?
    end

    def wp_client
      self.class.wp_client
    end
  end
end
