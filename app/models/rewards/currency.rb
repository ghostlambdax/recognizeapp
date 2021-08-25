module Rewards
  class Currency
    RECOGNIZE_BASE_CURRENCY = "USD".freeze # used for accounting

    BLACKLISTED_CURRENCIES_ISO_CODES = %w[xts].freeze

    def self.available_currencies
      @available_currencies ||= Money::Currency.all
    end

    def self.supported_currencies
      @supported_currencies ||= begin
        available_currencies - blacklisted_currencies - non_iso_currencies
      end
    end

    def self.supported_currencies_iso_codes
      @supported_currencies_iso_codes ||= supported_currencies.map(&:iso_code)
    end

    def self.blacklisted_currencies
      @blacklisted_currencies ||= begin
        available_currencies.select { |currency| currency.iso_code.in? blacklisted_currencies_iso_codes }
      end
    end

    def self.blacklisted_currencies_iso_codes
      BLACKLISTED_CURRENCIES_ISO_CODES
    end

    def self.non_iso_currencies
      @non_iso_currencies ||= available_currencies.select { |currency| currency.iso_numeric.blank? }
    end

    def self.get_money_currency(currency)
      currency.class == Money::Currency ? currency : Money::Currency.new(currency)
    rescue
      nil
    end

    def self.get_matching_currency_codes(search_values)
      search_values = Array(search_values)

      supported_currencies.map do |currency|
        currency.iso_code if search_values.map(&:downcase).include?(currency.iso_code.downcase)
      end.compact
    end

    def self.currency_prefix(currency, opts = {})
      default_opts = {format: :short}
      opts = default_opts.merge(opts)
      case opts[:format]
        when :short
          # Returns "$"
          opts[:name] = false
          opts[:iso_code] = false
        when :medium
          # Returns "$ USD"
          opts[:name] = false
        when :long
          # Returns "$ USD United States Dollar"
          opts
      end
      format_currency_prefix(currency, opts)
    end

    def self.format_currency_prefix(currency, opts = {})
      default_opts = { symbol: true, iso_code: true, name: true, name_prefix: true, name_prefix_str: '-' }
      opts = default_opts.merge(opts)
      currency = get_money_currency(currency)

      str_array = []
      if currency.present?
        %i[symbol iso_code name].each do |key|
          if opts[key] == true
            str_array << opts[:name_prefix_str] if key == :name && opts[:name_prefix] == true
            str_array << currency.send(key)
          end
        end
      end
      str_array.join(" ")
    end
  end
end
