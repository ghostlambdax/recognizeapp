class LandingPagesController < ApplicationController
  layout 'landing_pages'
  before_action :common_setup

  def show
    @title = "Enterprise Employee Engagement & Recognition Platform".html_safe
    @title_contd = "That Fits Seamlessly Into Your Workflow"
    @subtitle = "Perfect for companies with 500+ employees, Recognize is an employee engagement platform that integrates with the tools you already use such as Office 365, Slack, Yammer, Google Chrome, and more. The only platform inside Outlook and Workplace by Facebook!"
    @main_image = "pages/landing-pages-capterra/hall_of_fame.png"

    @video_link = "https://www.youtube.com/embed/2eYHSBUSkcA"
  end

  private

  def common_setup
    @use_marketing_manifest = true
    @use_landing_page_menu = true
  end


end
