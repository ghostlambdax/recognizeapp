class CompanyAdmin::TagsController < CompanyAdmin::BaseController
  def index
    @tags = company.tags.order(:name)
  end

  def create
    @tag = company.tags.build(tag_params)
    if @tag.valid?
      @tag.save
    else
      respond_with @tag
    end
  end

  def show
    @tag = company.tags.find(params[:id])
  end

  def edit
    @tag = company.tags.find(params[:id])
  end

  def update
    @tag = company.tags.find(params[:id])
    @tag.assign_attributes tag_params
    @tag.save

    if @tag.errors.present?
      respond_with @tag # use normal ajaxify
    else
      render action: "show" # bypass ajaxify, and force to update via js
    end
  end

  def destroy
    @tag = company.tags.find(params[:id])
    @tag.destroy
  end

  private

  def company
    @company
  end

  def tag_params
    params.require(:tag).permit(:name, :is_recognition_tag, :is_task_tag)
  end

end

