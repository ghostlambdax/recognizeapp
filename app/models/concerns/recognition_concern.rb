module RecognitionConcern
  extend ActiveSupport::Concern
  
  included do
    include ApprovalWorkflow
    include RecognitionApproval
    include Display
    include Privacy
    include Notification
  end
end