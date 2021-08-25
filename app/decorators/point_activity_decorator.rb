# frozen_string_literal: true
# Wrap up a point activity query and make its results
# appear as recognitions to a single recipient
class PointActivityDecorator < RecognitionRecipientDecorator

  def reference_activity
    self
  end

end
