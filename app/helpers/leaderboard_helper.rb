module LeaderboardHelper
  def leaderboard_report_path_method
    case 
    when on_company_nominations_controller?
      :company_admin_nominations_path
    when on_company_controller?
      :company_admin_top_employees_path      
    else
      :reports_path
    end
  end

  def leaderboard_path_args
    args = {badge_id: @badge.try(:id), team_id: @team.try(:id), company_role_id: @company_role.try(:id),
            start_date: params[:start_date], end_date: params[:end_date], interval: params[:interval]}
    args.merge!({sort: params[:sort],
                 attribute_filter_key: params[:attribute_filter_key],
                 attribute_filter_value: params[:attribute_filter_value]
                }) if on_company_controller?
    args.merge!({archive: params[:archive]}) if on_company_nominations_controller?
    args
  end

  def show_leaderboard_team_filter?
    on_company_controller?
  end

  def show_leaderboard_role_filter?
    on_company_controller?
  end

  def show_leaderboard_metric_selector?
    on_company_controller?
  end

  def leaderboard_class
    on_company_controller? ? "company_leaderboard" : "user_leaderboard"
  end

  def show_leaderboard_attribute_value_filter?
    on_company_controller?
  end

  def attribute_filter_key_select
    select_tag(
        :attribute_filter_key,
        options_for_select(attribute_filter_key_options, params[:attribute_filter_key]),
        class: "attribute-filter-key"
    )
  end

  def attribute_filter_key_options
    select_options = []
    select_options << [t('dict.filter_parameter.less_than'), 'lt']
    select_options << [t('dict.filter_parameter.less_than_or_equal_to'), 'lt_or_eq_to']
    select_options << [t('dict.filter_parameter.equal_to'), 'eq_to']
    select_options << [t('dict.filter_parameter.greater_than_or_equal_to'), 'gt_or_eq_to']
    select_options << [t('dict.filter_parameter.greater_than'), 'gt']
    select_options
  end

  private
  def on_company_controller?
    controller.kind_of?(CompanyAdmin::BaseController)
  end

  def on_company_nominations_controller?
    controller.class == CompanyAdmin::NominationsController
  end
end