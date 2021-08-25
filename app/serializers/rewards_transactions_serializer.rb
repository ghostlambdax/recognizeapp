class RewardsTransactionsSerializer < BaseDatatableSerializer
  include DateTimeHelper
  include ActionView::Helpers::NumberHelper

  attributes :company, :date, :description, :credit, :debit, :catalog

  def attributes
    attrs = super
    attrs.delete(:company) unless include_company?
    attrs
  end

  def company
    object.funds_account.company.domain
  end

  def date
    localize_datetime(object.created_at, :friendly_with_time)
  end

  def description
    object.description
  end

  def debit
    "-#{amount}" if object.debit?
  end

  def credit
    amount if object.credit?
  end

  def catalog
    # catalog can be sometimes be nil, like for manual credits
    object.catalog&.currency
  end

  private

  def include_company?
    context.controller_base == "admin_rewards"
  end

  def amount
    #
    # FIXME:
    #   - Can deposits be made in currencies other than USD?
    #   - How does this play along with catalogs with non-USD currency?
    #
    currency = "USD"
    money_amount = Money.from_amount(object.amount, currency)
    context.humanized_money_with_symbol(money_amount).no_zeros
  end
end
