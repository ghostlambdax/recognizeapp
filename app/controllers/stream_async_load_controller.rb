class StreamAsyncLoadController < ApplicationController
  filter_access_to :all

  def comments
    recognitions_comments_partial = recognitions_from_params.map do |r|
      if recognition_permitted?(r) && comments_for_recognition_permitted?(r)
        # Calling a function with a object will gives you a reference to that object. The function
        # `comments_for_recognition_permitted?` builds new comment and is reflected here. So we are
        # removing that un-persisted comment.
        r.comments.reset
        comments_partial = render_to_string(partial: 'recognitions/comments', locals: { recognition: r, comment_limit: 3, hide_comments_header: true })
        { recognition_id: r.id, comments: comments_partial }
      else
        { recognition_id: r.id }
      end
    end.compact
    render json: { recognitions_comments: recognitions_comments_partial }
  end

  def approvals
    recognition_approvals_partial = recognitions_from_params.map do |r|
      if recognition_permitted?(r)
        approvals_partial = render_to_string(partial: 'recognitions/recognition_approval_section', locals: { recognition: r, approvers_limit: 5 })
        { recognition_id: r.id, approvals: approvals_partial }
      else
        { recognition_id: r.id }
      end
    end
    render json: { recognitions_approvals: recognition_approvals_partial }
  end

  private

  def params_recognition_ids
    params.permit(recognition_ids: [])[:recognition_ids].map{ |id| id.to_i }
  end

  def recognitions_from_params
    Recognition.includes(:comments).where(id: params_recognition_ids)
  end

  def comments_for_recognition_permitted?(recognition)
    ((recognition.comments.present? && grid_view) || !grid_view) && (permitted_to?(:index, recognition.comments.build, context: :comments))
  end

  def recognition_permitted?(recognition)
    permitted_to? :show, recognition
  end

  def grid_view
    params[:grid_view] == 'true'
  end
end
