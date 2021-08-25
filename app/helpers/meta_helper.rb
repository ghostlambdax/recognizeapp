module MetaHelper
  def title
    t = content_for :title
    t = t.blank? ? "" : "| #{t}"
    return t
  end

  def page_id
    if id = content_for(:body_id) and id.present?
      return id
    else
      base = controller_base
      return "#{base}-#{controller.action_name}"
    end
  end

  def controller_base
     controller.class.to_s.gsub("Controller", '').underscore.gsub("/", '_')
  end

  def page_class
    controller.class.to_s.gsub("Controller", '').underscore.gsub("/", '_')+" "+content_for(:page_class).to_s
  end

  def base_page_title(keyword1 = 'Social & Integrated', full = false)
    keyword1 = keyword1.present? ? keyword1 : 'Social & Integrated'

    if full
      "#{keyword1} - Recognize"
    else
      "#{keyword1}, Employee Recognition Program - Recognize"
    end
  end

  RESOURCE_ACTIONS = [:index, :new, :create, :edit, :update, :destroy]

  def page_title
    custom_title = content_for(:title)
    isFullLength = custom_title.nil? ? false : custom_title.length > 30

    if current_user.blank?
      if custom_title.present?
        base_page_title(custom_title, isFullLength).html_safe
      else
        base_page_title(nil, isFullLength)
      end
    else
      controller_action_page_title
    end
  end

  def controller_action_page_title
    title = content_for(:title)

    if title.present?
      "#{title} | Recognize"
    else
      resourceful_page_title
    end

  end

  def resourceful_page_title
    case params[:action].to_sym
    when :new, :edit
      "#{pretty_action_name} #{controller_base.singularize.humanize} | Recognize"
    else
      "#{controller_base.humanize} | Recognize"
    end
  end

  def pretty_action_name
    controller.action_name.humanize
  end

  BASE_DESCRIPTION = "A social employee recognition & rewards program. Helps retain & engage your top staff within the apps they already use. Inside MS Teams, Microsoft 365, Workday, Jira, & more.".html_safe
  def page_description

    specific_description = content_for(:description)
    if specific_description
      description =  specific_description
    else
      description = BASE_DESCRIPTION
    end

    return description
  end

  def meta_keywords
    specific_keywords = content_for(:meta_keywords)
    general_keywords = "Recognize, Recognize App, employee recognition, employee benefits, employee rewards, employee service awards, employee birthdays, employee recognition program, manager-to-peer, employee nominations, enterprise gamification, social employee recognition, private employee recognition, people analytics, employee gift cards"

    if specific_keywords
      keywords = "#{specific_keywords}, #{general_keywords}"
    else
      keywords = general_keywords
    end

    return keywords
  end

end
