class CompanyAdmin::BulkMailersController < CompanyAdmin::BaseController
  def new
  end

  def create
    @mailer = BulkMailerForm.new(bulk_mailer_params)
    @mailer.send!

    respond_with @mailer
  end

  private
  def bulk_mailer_params
    params.require(:bulk_mailer_form)
          .permit(:group, :subject, :body, :sms_body,
                  roles: [], statuses: [], teams: [])
          .merge({sender: current_user, company: @company})
  end
end
