module BulkRecognition
  class Base
    attr_reader :file_parser, :schema, :options, :email_suffix, :company_id

    def initialize(schema, email_suffix, options = {})
      @schema = schema
      @schema[:remarks] = schema.values.max + 1 unless schema[:remarks]
      @email_suffix = email_suffix
      @options = default_options.merge(options)
      @options[:input_format] ||= 'html'
      @company_id = options[:company_id]

      @file_parser = BulkRecognition::FileParser.new(@options)
    end

    def default_options
      { from_bulk: true, is_private: true, skip_send_limits: true }
    end

    def perform
      raise NotImplementedError
    end

    def validate
      raise NotImplementedError
    end

    def remote?
      options[:remote_file_url].present? ? true : false
    end

    def company
      @company ||= Company.find(company_id)
    end
  end
end
