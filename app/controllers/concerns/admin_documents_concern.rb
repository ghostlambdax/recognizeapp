module AdminDocumentsConcern
  extend ActiveSupport::Concern

  included do
    include DocumentsHelper
    filter_access_to [:show, :destroy], attribute_check: true
    before_action :enforce_type, only: [:index]
    before_action :set_document, only: [:show, :destroy]
    helper_method :manager_admin_controller?, :tertiary_title
    layout 'company_admin_tertiary'
  end

  def index
    @datatable = datatable
    gon.max_file_upload_size_in_mb = Document.new.file.size_range.max / 1.megabyte
    respond_with(@datatable)
  end

  def show
    if storage_is_fog?
      redirect_to @document.file.url
    else
      send_file @document.file.path, filename: @document.original_filename, disposition: 'attachment'
    end
  end

  def create
    @document = Document.new(params_for_create)
    if @document.save
      render json: { document_id: @document.id, message: "Document succesfully added!" }
    else
      respond_with @document
    end
  end

  def destroy
    @document.destroy
  end

  private

  def storage_is_fog?
    DocumentUploader.storage == CarrierWave::Storage::Fog
  end

  def set_document
    @document = document_scope.find(params[:id])
  end

  def document_scope
    raise "Not implemented! Must be implemented by client class."
  end

  def datatable
    raise "Not implemented! Must be implemented by client class."
  end

  def params_for_create
    fields = [:file, :description]
    if current_user.acting_as_superuser
      fields += [:due_date, :type]
    end
    # By using fetch with default value, it also handles empty file input form submissions.
    params.fetch(:document, {}).permit(fields).tap do |p|
      p[:uploader_id] = uploader.id
      p[:company_id] = @company.id
    end
  end

  def uploader
    session.key?(:superuser) ? User.find(session[:superuser]) : current_user
  end

  def manager_admin_controller?
    controller_path.match(/^manager_admin/).present?
  end

  # tertiary methods
  def tertiary_title
    t("dict.document_center")
  end

  def enforce_type
    redirect_to documents_index_endpoint(type: "downloads") if params[:type].blank?
  end
end
