module AdminRecognitionsConcern
  extend ActiveSupport::Concern
  included do
    include ServerSideExportConcern
    include TrumbowygHelper

    before_action :set_recognition, only: [:approve, :deny]
    before_action :ensure_status, only: [:index]
    before_action :massage_params_based_on_status
    before_action :set_gon_attrs_for_trumbowyg, only: :index

    layout 'admin_recognitions'
    helper_method :manager_admin_controller?
  end

  def index
    @recognitions_datatable = datatable
    @pending_recognition_count = @recognitions_datatable.report.total_pending_recognitions
    if request.xhr?
      respond_with @recognitions_datatable
    else
      render action: "index"
    end
  end

  def approve
    points = params[:points] || 0  # points are absent when badge has no point_values
    @recognition.approve_pending_recognition(resolver: current_user, message: params[:message],
                                             input_format: params[:input_format], points: points, request_form_id: params[:request_form_id])

    if @recognition.errors.empty?
      render "company_admin/recognitions/approve" # shared file
    else
      render json: { errors: @recognition.errors }, status: 422
    end
  end

  def deny
    @recognition.deny_pending_recognition(resolver: current_user, message: params[:denial_message])
    if @recognition.errors.empty?
      render "company_admin/recognitions/deny" # shared file
    else
      render json: { errors: @recognition.errors }, status: 422
    end
  end

  def filter_present?
    filters = params[:filter]
    return false if filters.blank?

    %i[sender_company_role sender_country sender_department
       receiver_company_role receiver_country receiver_department].any? do |filter|
      filters.dig(filter, :id).present?
    end
  end

  private

  def datatable
    report = recognition_report(params[:from], params[:to])
    datatable_class = manager_admin_controller? ? ManagerAdmin::RecognitionsDatatable : RecognitionsDatatable
    datatable_class.new(view_context, @company, report)
  end

  def common_report_opts
    opts = {}
    opts[:user_context] = current_user
    if @company.allow_quick_nominations?
      opts[:include_nomination_votes] = true
    end
    opts
  end

  def set_recognition
    @recognition = Recognition.find(params[:id])
  end

  def ensure_status
    # if status is not included as query parameter, 
    # redirect to approved view
    if params[:status].blank?
      if manager_admin_controller?
        redirect_to manager_admin_recognitions_path(status: 'approved')
      else
        redirect_to company_admin_recognitions_path(status: 'approved')
      end
      return false
    end
  end

  def massage_params_based_on_status
    case params[:status]
    when 'pending_approval'
      params[:from] ||= @company.created_at - 1.day
      params[:to] ||= Time.current + 1.day
      params[:recognitions] ||= {}
      params[:recognitions][:interval] = Interval.custom.to_i
      params[:recognitions][:start_date] = params[:from]
      params[:recognitions][:end_date] = params[:to]
    end
  end

  def manager_admin_controller?
    controller_path.match(/^manager_admin/).present?
  end
end
