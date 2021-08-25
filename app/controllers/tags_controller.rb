class TagsController < ApplicationController
  def index
    @tags = current_user.company.tags.
      recognition_taggable.
      where("name like ?", "%#{params[:q]}%").limit(params[:limit] || 50)

    respond_to do |format|
      format.json { render json: @tags }
    end
  end
end
