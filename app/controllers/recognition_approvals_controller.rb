class RecognitionApprovalsController < ApplicationController
  skip_before_action :ensure_correct_company
  before_action :build_recognition_approval, only: [:create]

  filter_access_to :create, :destroy, attribute_check: true

  def create
    @recognition_approval.save
    # need to reload the associated objects for the point calculator
    # ugly, i know...
    @recognition_approval.giver.reload
    @recognition_approval.recognition.reload

    if !@recognition_approval.persisted?
      # why didn't it save?
      # ExceptionNotifier.notify_exception(Exception.new("Could not save recognition approval"), data: {errors: @recognition_approval.errors.full_messages.to_sentence})
      Rails.logger.debug "Could not save recognition approval: #{{errors: @recognition_approval.errors.full_messages.to_sentence}}"
    end
  end

  def destroy
    @approval = RecognitionApproval.joins(:recognition).includes(:recognition).find(params[:id])

    @approval.destroy! # don't hide, do full wipe

    # need to reload the associated objects for the point calculator
    # ugly, i know...
    @approval.giver.reload
    @approval.recognition.reload

  end

  private

  def build_recognition_approval
    recognition = Recognition.find(params[:recognition_id])
    viewer_params = {viewer: params[:viewer], viewer_description: params[:viewer_description]}
    @recognition_approval = recognition.build_approval(current_user, viewer_params)
  end

end
