module CurrencyHelper
  def currencies_options_for_select(supported_currencies = Rewards::Currency.supported_currencies)
    supported_currencies.map do |currency|
      [
        Rewards::Currency.currency_prefix(currency, format: :long),
        currency.iso_code,
        { data: { currency_symbol: currency.symbol } }
      ]
    end
  end
end
