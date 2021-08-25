# encoding : utf-8
require 'money/bank/currencylayer_bank'
Money.locale_backend = :currency

MoneyRails.configure do |config|

  # To set the default currency
  #
  config.default_currency = :usd

  # Set default bank object
  #
  # Example:
  # config.default_bank = EuCentralBank.new
  clb = Money::Bank::CurrencylayerBank.new
  clb.access_key = Recognize::Application.config.rCreds.dig('currency_layer','api_key')
  clb.ttl_in_seconds = 3600
  clb.cache = begin
    tmp_cache = File.join(Rails.root, 'tmp/cache')
    FileUtils.mkdir_p(tmp_cache) unless File.exists?(tmp_cache)
    File.join(tmp_cache, 'currency')
  end
  config.default_bank = clb

  # Add exchange rates to current money bank object.
  # (The conversion rate refers to one direction only)
  #
  # Example:
  # config.add_rate "USD", "CAD", 1.24515
  # config.add_rate "CAD", "USD", 0.803115

  # To handle the inclusion of validations for monetized fields
  # The default value is true
  #
  # config.include_validations = true

  # Default ActiveRecord migration configuration values for columns:
  #
  # config.amount_column = { prefix: '',           # column name prefix
  #                          postfix: '_cents',    # column name  postfix
  #                          column_name: nil,     # full column name (overrides prefix, postfix and accessor name)
  #                          type: :integer,       # column type
  #                          present: true,        # column will be created
  #                          null: false,          # other options will be treated as column options
  #                          default: 0
  #                        }
  #
  # config.currency_column = { prefix: '',
  #                            postfix: '_currency',
  #                            column_name: nil,
  #                            type: :string,
  #                            present: true,
  #                            null: false,
  #                            default: 'USD'
  #                          }

  # Register a custom currency
  #
  # Example:
  config.register_currency = {:priority=>100,
                              :iso_code=>"NPR",
                              :name=>"Nepalese Rupee",
                              :symbol=>"रु",
                              :disambiguate_symbol=>"NPR",
                              :alternate_symbols=>["Rs", "रू"],
                              :subunit=>"Paisa",
                              :subunit_to_unit=>100,
                              :symbol_first=>true,
                              :html_entity=>"&#x20A8;",
                              :decimal_mark=>".",
                              :thousands_separator=>",",
                              :iso_numeric=>"524",
                              :smallest_denomination=>1}
  # Specify a rounding mode
  # Any one of:
  #
  # BigDecimal::ROUND_UP,
  # BigDecimal::ROUND_DOWN,
  # BigDecimal::ROUND_HALF_UP,
  # BigDecimal::ROUND_HALF_DOWN,
  # BigDecimal::ROUND_HALF_EVEN,
  # BigDecimal::ROUND_CEILING,
  # BigDecimal::ROUND_FLOOR
  #
  # set to BigDecimal::ROUND_HALF_EVEN by default
  #
  # config.rounding_mode = BigDecimal::ROUND_HALF_UP
  config.rounding_mode = BigDecimal::ROUND_HALF_EVEN


  # `no_cents_if_whole` outisde `default_format` will overwrite the one inside.
  config.no_cents_if_whole = false

  # Set default money format globally.
  config.default_format = {
      :no_cents_if_whole => false,
      # :symbol => nil,
      # :sign_before_symbol => nil
  }

  # Set default raise_error_on_money_parsing option
  # It will be raise error if assigned different currency
  # The default value is false
  #
  # Example:
  # config.raise_error_on_money_parsing = false
end
