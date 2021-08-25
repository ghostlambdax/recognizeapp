# frozen_string_literal: true

class DatatableExporterJob < ApplicationJob
  queue_as :export

  def perform(datatable, requested_at, timezone)
    Time.use_zone(timezone) do
      format = datatable.view.params["file_format"]
      Exporter.export!(datatable, format, requested_at)
      Rails.logger.debug "Completed without exception - DatatableExporterJob on: #{datatable}"
    end
  rescue StandardError => e
    Rails.logger.debug "Caught exception in DatatableExporterJob on: #{datatable} - #{e}"
    Rails.logger.debug e.backtrace.join("\n")
    ExceptionNotifier.notify_exception(e, data: {domain: datatable.company&.domain, user_id: datatable.current_user&.id, datatable: datatable.class})
  end

  def named_job_arguments(job_args, hash)
    datatable = job_args[0]
    hash["company_id"] = datatable.company.id
    hash["datatable_class"] = datatable.class.to_s
    hash["current_user_id"] = datatable.current_user.id
    return hash
  end

  def signature
    # 1. This signature is specifically to be unique - and thus never have a duplicate
    #     - Even if a user hits export twice on the same view - it could have different data
    #       And so, we should basically always produce export when user requests
    # 2. The signature is verbose so that we can track the jobs in the database - and clear them out
    #    if necessary
    "DatatableExport-#{@datatable_class}-#{@company_id}-#{@current_user_id}-#{self.job_id}"
  end

  class Exporter
    include DatatablesHelper

    attr_reader :datatable, :format, :requested_at

    delegate :company, :current_user, :data, to: :datatable

    def self.export!(datatable, format, requested_at)
      new(datatable, format, requested_at).export
    end

    def initialize(datatable, format, requested_at)
      @datatable = datatable
      @format = format
      @requested_at = requested_at

      # force paging parameters to include everything
      # TODO: allow different parameters to say whether
      #       to include/exclude search filter (Eg a total dump or just exact search query[date + search box])
      #       The only thing we want to avoid is the client side paging
      @datatable.disable_paging!
      @datatable.disable_attribute_escaping
    end

    def csv_file
      @csv_file ||= begin
        temp_file = Tempfile.new([tmp_file_path, file_extension])
        csv = CSV.new(temp_file)

        # data is json (array of hashes)   
        csv << headers

        data.each do |row|
          csv << format_row(row)
        end
        temp_file.rewind
        temp_file
      end
    end

    def description
      str = "#{datatable.namespace.humanize} export"
      extra_parts = []

      if datatable.date_range.present?
        extra_parts << "#{datatable.date_range.start_date.to_formatted_s(:default)} - #{datatable.date_range.end_date.to_formatted_s(:default)}"
      end

      if datatable.search_query.present?
        extra_parts << "\"#{datatable.search_query}\""
      end

      if extra_parts.present?
        str = "#{str}: #{extra_parts.join(", ")}"
      end
      str
    end

    def excel_file
      @excel_file ||= begin
        package = Axlsx::Package.new
        workbook = package.workbook
        workbook.add_worksheet(name: "Sheet 1") do |worksheet|
          add_data_to_worksheet(worksheet)
        end

        # Write the data_sheet to file.
        package.use_shared_strings = true
        temp_file = Tempfile.new([tmp_file_path, file_extension])
        package.serialize temp_file
        temp_file
      end
    end

    def export
      tmp_file = temp_file
      filename = tmp_file_path + file_extension
      doc = Document.create!(
          file: tmp_file,
          original_filename: filename,
          company_id: company.id,
          uploader_id: User.system_user.id,
          requester_id: requester.id,
          requested_at: requested_at,
          description: description
        )
      ExportNotifier.document_ready(doc, datatable.manager_admin_table?).deliver_now
    ensure
      tmp_file&.close
      tmp_file&.unlink
    end

    def file_extension
      format == 'csv' ? ".csv" : ".xlsx"
    end

    def temp_file
      format == "csv" ? csv_file : excel_file
    end

    def requester
      current_user
    end

    def tmp_file_path
      @tmp_file_path ||= "#{company.domain}-#{datatable.namespace}-export"
    end

    private

    def add_data_to_worksheet(worksheet)
      data_sheet_styles = AccountsSpreadsheetImport::DataSheet.custom_styles(worksheet)
      if data.length > 0
        worksheet.add_row headers, style: ([data_sheet_styles[:bold]] * headers.length)
        data.each do |row|
          worksheet.add_row format_row(row)
        end
      else
        # No one should see this. If there is no data,
        # we should send a seperate email.
        # However, this is a safety precaution to prevent this process
        # from bombing out just in case we flow through here
        worksheet.add_row ["There is no data for this search query"]
      end
    end

    def format_cell(attr, value)
      spec = spec_for_column(attr)
      if spec.key?(:export_format)
        func = export_format_functions_rb[spec[:export_format]]
        func.call(value)
      else
        value
      end
    end

    def format_row(row)
      # doing the loop this way ensures we add columns
      # in the proper order since row is a hash
      datatable.column_spec.inject([]) do |arr, col|
        attr = col[:attribute]
        value = row[attr.to_sym]
        if include_column?(attr)
          arr << format_cell(attr, value)
        end
        arr
      end
    end

    def headers
      datatable.column_spec
        .select { |col| include_column?(col[:attribute]) }
        .map { |col| col[:title] || col[:attribute].to_s.humanize }
    end

    # Not supporting both :visible and :if keys on the column spec
    def include_column?(attr)
      spec = spec_for_column(attr)
      return false if spec.nil? # if no spec for a column, skip it
      return spec[:visible] if spec.key?(:visible) && !spec[:visible] # if :visible key is there, use its value
      return spec[:export] if spec.key?(:export)
      return true unless spec.key?(:if) # if :if condition is present, call it

      if_condition = spec[:if]
      datatable.instance_eval(&if_condition)
    end

    def spec_for_column(attr)
      @specs_for_columns ||= {}
      @specs_for_columns[attr] ||= datatable.column_attributes.values.find { |ca| ca[:attribute].to_sym == attr.to_sym }
      @specs_for_columns[attr]
    end
  end
end
