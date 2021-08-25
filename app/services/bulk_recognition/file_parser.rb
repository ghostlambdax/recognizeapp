module BulkRecognition
  class FileParser
    attr_reader :options, :file_path

    def initialize(options)
      @options = options
      @file_path = options[:file_path] || options[:remote_file_url]
      @remote = options[:remote_file_url].present? ? true : false
    end

    def data
      parse_data
    end

    private

    def parse_raw_file_content
      case file_extension
      when 'xlsx'
        Roo::Spreadsheet.open(file).parse
      when 'csv'
        csv_opts = { }
        csv_opts[:encoding] = options[:encoding] if options[:encoding].present?
        Roo::CSV.new(file, csv_options: csv_opts).parse
      else
        raise Exceptions::UnknownFileFormat
      end
    end

    def parse_data
      raw_data = parse_raw_file_content.delete_if { |row| row.all?(&:blank?) }
      raw_data.shift
      raw_data
    end

    def file
      @remote ? download_remote_file : @file_path
    end

    def file_extension
      File.extname(file_path).delete(".")
    end

    def file_path
      return @file_path if @file_path.present?

      raise Exceptions::EmptyFilePathError
    end

    def download_remote_file
      Rails.logger.info "Downloading remote file..."
      Down.download(file_path)
    end
  end
end
