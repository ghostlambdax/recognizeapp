class ArticlesController < ApplicationController
  include CmsConcern
  cms_action :index
  
  layout 'article'
  before_action :common_setup

  def ui_design_trends_2019
    @article_canonical = ui_design_trends_2019_url
  end


  def run_volunteer_program

  end

  def index
    @cms_articles = wp_client.articles
    render layout: "application"
  end

  def banking_survey
    @article_canonical = banking_survey_url
  end

  def mental_health_research
    @article_canonical = mental_health_research_url
  end

  def employee_recognition_report_2019
    @article_canonical = employee_recognition_report_2019_url
  end

  def top_recognition_ideas
    @button = false
    @list = true
    @link1501 = '<a target="_blank" href="https://www.amazon.com/gp/product/0761168788/ref=as_li_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=0761168788&linkCode=as2&tag=recognizeapp-20&linkId=1fa1855f97a04dd89307cc498d67d5bf">1501 Ways to Reward Employees</a>'
    @article_canonical = top_employee_recognition_ideas_url
  end

  def employee_recognition_app_guide
    @article_canonical = employee_recognition_app_guide_url
  end

  def holiday_party
    @article_canonical = holiday_party_url
  end

  def employee_recognition_trends_2019
    @article_canonical = employee_recognition_trends_2019_url
  end

  def hr_trends_2019
    @article_canonical = hr_trends_2019_url
  end

  def ways_great_hr_manager
    @article_canonical = ways_great_hr_manager_url
  end

  def employee_recognition_stats_for_healthcare
    @article_canonical = employee_recognition_stats_for_healthcare_url
    @title = "Nurse Burnout Research"
  end

  def ways_foster_employee_engagement
    @article_canonical = ways_foster_employee_engagement_url
  end

  def engage_employees_office_365
    @article_canonical = engage_employees_office_365_url
  end

  def hr_trends_2020
    @article_canonical = hr_trends_2020_url
  end

  def ways_to_combat_coronavirus
    @article_canonical = ways_to_combat_coronavirus_url
  end

  def become_a_zoom_power_user
    @article_canonical = become_a_zoom_power_user_url
  end

  def combat_healthcare_burnout
    @article_canonical = combat_healthcare_burnout_url
  end

  def employee_recognition_in_okta
    @article_canonical = employee_recognition_in_okta_url
  end

  def cultivate_positive_remote_work_experience
    @article_canonical = cultivate_positive_remote_work_experience_url
    @title = "Cultivate a Positive Remote Work Experience"
  end

  def ways_to_use_recognize_during_covid_19
    @article_canonical = ways_to_use_recognize_during_covid_19_url
    @title = "5 Ways to Use Recognize during COVID-19"
  end

  def amazing_award_certificates
    @article_canonical = amazing_award_certificates_url
    @title = "10 Amazing Award Certificate Templates"
  end

  private

  def common_setup
    @use_marketing_manifest = true
  end

end
