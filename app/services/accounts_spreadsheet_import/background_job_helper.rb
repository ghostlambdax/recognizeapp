# frozen_string_literal: true

module AccountsSpreadsheetImport
  module BackgroundJobHelper
    def before(job)
      # When DelayedJob is not running (say in Development mode), to avoid 'can not update on a new record object' error,
      # save the job.
      job.save! if job.new_record? && !Rails.env.production?
      super
    end

    def signature
      "accounts-spreadsheet-importer-#{company.id}"
    end

    def method_name
      "perform"
    end

    def args
      { company_id: company_id, importing_actor_signature: importing_actor_signature }
    end

    def queue_name
      'import'
    end

    def update_progress_max(*)
      super if track_progress?
    end

    def update_progress(*)
      super if track_progress?
    end

    def update_stage(*)
      super if track_progress?
    end

    def track_progress?
      # @job isn't present in this class when perform is called directly
      # eg, when called by AccountsSpreadsheetImport::RemoteImportService
      !Rails.env.test? && @job.present?
    end
  end
end
