# frozen_string_literal: true
# Wrap up a recognition recipient query and make its results
# appear as recognitions to a single recipient
class RecognitionRecipientDecorator < ApplicationDecorator
  delegate_all

  delegate :badge, :slug, :sender, :sender_name, :sender_email, :message, :resolver_id, :status_label, to: :recognition

  def nomination_vote_map
    context[:nomination_vote_map]
  end

  def recognition
    object.recognition
  end

  def reference_recipient
    object.user
  end

  def reference_recognition_tags
    recognition.recognition_tags
  end

  def reference_activity
    recognition.point_activities.detect{ |pa| pa.user_id == reference_recipient.id }
  end

  def reference_recipient_teams
    user.teams
  end

  def reference_recipient_nominated_badge_ids
    return if nomination_vote_map.blank?
    @reference_recipient_nominated_badge_ids ||= begin
      nomination_votes = nomination_vote_map["#{recognition.slug}:#{reference_recipient.id}"]
      if nomination_votes.present?
        recognition.reference_recipient_nominated_badge_ids = nomination_votes.map{ |nv| nv.nomination.campaign.badge_id }
      end
    end
  end

  def reference_recipient_department
    user.department
  end

  def reference_recipient_country
    user.country
  end

  def to_param
    recognition_recipient.to_param
  end

  def method_missing(method_name, *args, &block)
    if recognition_recipient.respond_to?(method_name)
      recognition_recipient.send(method_name, *args, &block)
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    recognition_recipient.respond_to?(method_name) || super
  end  
end
