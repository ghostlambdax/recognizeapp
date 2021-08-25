module Recognize
  module Liquid
    module Filters
      include ActionView::Helpers::JavaScriptHelper
      def escape_js(str)
        escape_javascript(str)
      end     
    end
  end
end
::Liquid::Template.register_filter(Recognize::Liquid::Filters)
