# frozen_string_literal: true

class CompanyAdmin::CommentsController < CompanyAdmin::BaseController
  include ServerSideExportConcern

  def index
    # @comments = Recognition.where(sender_company_id: 1).joins(:comments).includes(:comments).map(&:comments).flatten.reject(&:blank?)
    @comments_datatable = datatable
    respond_with(@comments_datatable)
  end

  private

  def datatable
    CommentsDatatable.new(view_context, @company)
  end
end
