# Finds the multiple times submitted or approved recognitions. The whole logic depends on the count of recognition sender's
# point activities. One recognition should have only one recognition_sender type point activity but when recognition
# approved multiple times, it will register multiple recognition_sender type point activities.
#
# Usage examples:
# - Get all the duplicate submitted recognitions
#     `Utility::DuplicateFinder::PointActivity.recognitions`
#
# - Remove duplicate submitted recognitions point activities
#     `Utility::DuplicateFinder::PointActivity.remove_duplicate_activities(recognition_or_id: 124, company_or_id: 3)`
#
#       * parameters
#         - `recognition_or_id` is optional
#         - `company_or_id` is optional
#
# - Use dry_run option to get all duplicate point activities
#     `Utility::DuplicateFinder::PointActivity.all`
#   or
#     `Utility::DuplicateFinder::PointActivity.remove_duplicate_activities(dry_run: true)`
#
class Utility::DuplicateFinder::PointActivity
  def self.all
    self.remove_duplicate_activities(dry_run: true)
  end

  def self.recognitions
    duplicate_recognitions = ::PointActivity.where(activity_type: 'recognition_sender').group(:recognition_id).having("COUNT(recognition_id) > 1").pluck(:recognition_id)
    Recognition.where(id: duplicate_recognitions)
  end

  # First find all the duplicate submitted recognitions, then remove the duplicate point activities of a sender and recipients.
  # Point Activities created at first are assumed as the original one and all other are duplicate one.
  def self.remove_duplicate_activities(recognition_or_id: nil, company_or_id:  nil, dry_run: false)
    recognition_or_id = Recognition.find(recognition_or_id) if recognition_or_id.present? && !recognition_or_id.is_a?(Recognition)
    company_or_id = Company.find(company_or_id) if company_or_id.present? && !company_or_id.is_a?(Company)

    dup_recognitions = recognition_or_id ? [recognition_or_id] : self.recognitions.includes(:point_activities)
    dup_recognitions = dup_recognitions.where(sender_company_id: company_or_id.id) if company_or_id && recognition_or_id.nil?

    report_generator = ReportGenerator.new(dry_run: dry_run)
    dup_recognitions.each do |recognition|
      removed_activities = []
      duplicate_activity_remover = DuplicatePointActivityRemover.new(recognition, dry_run)
      begin
        removed_activities << duplicate_activity_remover.remove_senders_activities
        removed_activities << duplicate_activity_remover.remove_recipients_activities
      rescue => e
        report_generator.add_error(recognition, e)
      end
      report_generator.add_success(recognition, removed_activities.flatten) if removed_activities.present?
    end
    report_generator.report
  end

  class DuplicatePointActivityRemover
    attr_reader :recognition, :dry_run

    def initialize(recognition, dry_run)
      @recognition = recognition
      @dry_run = dry_run
    end

    def remove_senders_activities
      dup_activities = recognition.point_activities.where(activity_type: "recognition_sender").order("created_at ASC")[1..-1]
      return dup_activities if dry_run

      dup_activities.map(&:destroy)
    end

    def remove_recipients_activities
      recipients_activities = recognition.point_activities.where(activity_type: 'recognition_recipient')
      recipients_activities.group_by(&:user_id).map do |_uid, point_activities|
        dup_activities = point_activities.sort_by(&:created_at)[1..-1]
        dry_run ? dup_activities : dup_activities.each(&:destroy)
      end
    end
  end

  class ReportGenerator < Array
    attr_reader :dry_run

    def initialize(dry_run: false)
      @dry_run = dry_run
    end

    def report
      final_report = self.inject({ success: [], errors: [] }) do |result, r|
        r[:success] ? result[:success].push(r) : result[:errors].push(r)
        result
      end
      dry_run ? final_report[:success] : final_report
    end

    def add_success(recog, records)
      self << {
        recognition_id: recog.id,
        success: true,
        "#{dry_run ? :dup : :removed}_activities": records
      }
    end

    def add_error(recog, err)
      Rails.logger.error "Utility::DuplicateFinder::Recognition.remove_duplicate_activities - failed for recognition_id: #{recog.id}"
      Rails.logger.error err.message
      ExceptionNotifier.notify_exception(err, { data: { recognition_id: recog.id } })

      self << {
        recognition_id: recog.id,
        errors: err.message
      }
    end
  end
end
