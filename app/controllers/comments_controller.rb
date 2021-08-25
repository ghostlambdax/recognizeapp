class CommentsController < ApplicationController
  before_action :load_recognition
  before_action :build_comment, only: [:create]

  filter_access_to :all, attribute_check: true

  def create
    @comment.save

    comment_partial = @comment.persisted? ? render_to_string( @comment) : ''
    respond_with @comment, onsuccess: {method: "fireEvent", params: {name: "comment_add", recognition_id: @recognition.id, comment:  comment_partial}}
  end

  def show
    @comment = Comment.find(params[:id])
  end

  # Because #edit is a GET request, we bypass Ajaxify, and thus must handle differently
  # this makes rendering something like the cancel link infinitely easier to implement
  # ie, it doesn't couple the javascript to the routing structure
  def edit
    @comment = Comment.find(params[:id])
  end

  def update
    @comment = Comment.find(params[:id])
    @comment.update(comment_params)
  end

  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy
  end

  def hide
    @comment = Comment.find(params[:id])
    @comment.hide!
  end

  def unhide
    @comment = Comment.find(params[:id])
    @comment.unhide!
  end

  protected
  def load_recognition
    @recognition = Recognition.find(params[:recognition_id])
  end

  def build_comment
    comment_attrs = comment_params.merge(
      commenter: current_user,
      viewer: params[:viewer],
      viewer_description: params[:viewer_description]
    )
    @comment = @recognition.comments.build(comment_attrs)
  end

  def comment_params
    params.require(:comment).permit(:content)
  end
end
