module BulkRecognition
  class Importer < Base
    attr_reader :bulk_imported_at, :total_records_count, :successful_records_count,
                :failed_records_count, :detail_to_be_logged

    def self.run(schema, email_suffix, options)
      bulk_recognizer = self.new(schema, email_suffix, options)
      if bulk_recognizer.validate
        puts "Bulk recognition is underway. You will be notified on slack after completion"
        if bulk_recognizer.remote?
          bulk_recognizer.delay(queue: 'remote_import').run
        else
          bulk_recognizer.run
        end
      else
        puts "Bulk Recognition was aborted due to the following validation errors."
        puts(bulk_recognizer.errors.full_messages.map { |e| e.indent(2) })
      end
    end

    def initialize(schema, email_suffix, options = {})
      @bulk_imported_at = options[:bulk_imported_at]
      @total_records_count = 0
      @failed_records_count = 0
      @successful_records_count = 0
      @log_list = []
      @problematic_records = []
      super
    end

    def run
      @total_records_count = file_parser.data.length
      file_parser.data.each do |row|
        puts "recognizing with #{row}"
        begin
          recognizer = Recognizer.new(row, self)
          recognizer.recognize
          unless recognizer.succeeded?
            add_to_problematic_records(row, recognizer.remarks)
          end
          @log_list << recognizer.data_to_log
        rescue => e
          add_to_problematic_records(row, "Error - #{e.message}")
          Rails.logger.error "BulkRecognition::Importer#run - failed for #{row}: #{e.message}"
          record_attributes = schema.dup
          record_attributes.each { |(k, v)| record_attributes[k] = row[v] }
          ExceptionNotifier.notify_exception(e, { data: { **record_attributes } })
        end
      end
      log_results_and_send_notification
    end

    def validate
      validator.valid?
    end

    def errors
      validator.errors
    end

    private

    def add_to_problematic_records(row, remarks)
      @failed_records_count += 1
      row[schema[:remarks]] = remarks
      @problematic_records << row
    end

    def log_results_and_send_notification
      # log results
      logger = Rails.logger
      logger.info "[Bulk Recognition - started at: #{bulk_imported_at}]"
      @log_list.each do |item|
        if item.first == "Success"
          logger.info item.last
        else
          logger.error item.last
        end
      end

      send_slack_notification
    end

    def send_slack_notification
      channel = failed_recognitions_report.nil? ? '#system-notifications' : '#support-alerts'
      ::Recognizebot.say(text: "Bulk Recognition Completed", blocks: report_blocks_for_slack.to_json, channel: channel)
    end

    def recognition_summary
      OpenStruct.new(
        started_at: bulk_imported_at,
        completed_at: Time.current,
        total_records_count: @total_records_count,
        successful_records_count: @total_records_count - @failed_records_count,
        failed_records_count: @failed_records_count
      )
    end

    def failed_recognitions_report
      return if @problematic_records.blank?
      return @failed_recognitions_file_document unless @failed_recognitions_file_document.nil?

      failed_recogntions_temp_file = BulkRecognition::ResultSheet.new(@problematic_records).create
      description = "List of failed recognitions"
      system_user = User.system_user
      @failed_recognitions_file_document = Document.create!(
        file: failed_recogntions_temp_file,
        company_id: company.id,
        uploader_id: system_user.id,
        original_filename: "Bulk_Recognition_result_#{bulk_imported_at.strftime("%Y_%b_%d_%I_%M_%p")}.xlsx",
        requester_id: system_user.id,
        requested_at: Time.current,
        description: description,
        metadata: recognition_summary.to_h
      )
      failed_recogntions_temp_file&.close!
      @failed_recognitions_file_document
    end

    def validator
      @validator ||= Validator.new(self)
    end

    def failed_recognitions_report_link
      Rails.application.routes.url_helpers.company_admin_document_url(failed_recognitions_report, network: company.domain, host: Rails.configuration.host)
    end

    def report_blocks_for_slack
      if failed_recognitions_report.nil?
        title = "Bulk recognition import completed successfully without any failures."
      else
        title = "Bulk recognition import completed with some failures."
        failed_report_link = build_slack_block(:link, text: "Click to download failed recognitions report", link: failed_recognitions_report_link )
      end

      bulk_result = recognition_summary.to_h.except(:completed_at).map { |k,v| "_#{k.to_s.humanize}_: #{v}" }.join("\n")
      [
        build_slack_block(:section, text: ":information_source: *Bulk Recognition Report for #{company.domain}* :information_source:"),
        build_slack_block(:divider),
        build_slack_block(:section, text: "*#{title}*"),
        build_slack_block(:section, text: bulk_result)
      ].push(failed_report_link).compact
    end

    def build_slack_block(name, opts = {})
      SlackBlockBuilder.send(name, opts)
    end

    class SlackBlockBuilder
      class << self
        def section(text: , text_type: 'mrkdwn')
          {
            "type": "section",
            "text": {
              "type": text_type,
              "text": text
            }
          }
        end

        def divider(*)
          {
            "type": "divider"
          }
        end

        def link(text: , link:)
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "<#{link}|#{text}>"
            }
          }
        end
      end
    end
  end
end
