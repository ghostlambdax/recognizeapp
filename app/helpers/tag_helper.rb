# Helpers to generate HTML
# You can call these helpers from HTML files without a block also.
# e.g. <%= page_nav({title: 'Rewards', primary:  }) do ... end %>

module TagHelper

  def page_nav(options = {})
    render layout: "styleguide/partials/page_nav", locals: options do
      yield if block_given?
    end
  end

  def tabs(list, options = {})
    tab_array = ["<nav class='tab-nav' role='tablist'>"]

    toggle = options[:js] == false ? '' : "data-toggle='tab'"

    list.each do |tab|
      if tab[:active] == true
        active_classname = "active"
      end

      tab_array << "<li role='presentation' class='#{active_classname}'><a href='#{tab[:href]}' aria-controls='#{tab[:title]}' class='#{tab[:link_classes]}' role='tab' #{toggle}>#{tab[:title]}</a></li>"
    end

    tab_array << "</nav>"

    tab_array.join.html_safe
  end

  def page_layout(options = {})
    render layout: "styleguide/partials/page", locals: options do
      yield if block_given?
    end
  end
end
