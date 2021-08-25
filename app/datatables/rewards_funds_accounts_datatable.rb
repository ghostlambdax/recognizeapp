# frozen_string_literal: true

class RewardsFundsAccountsDatatable < Litatable
  COLUMN_SPEC = [
    {attribute: :domain, orderable: true, sort_column: "companies.domain"},
    {attribute: :name, orderable: true, sort_column: "companies.name"},
    {attribute: :balance, orderable: true, sort_column: "funds_accounts.balance", width: "5%"},
    {attribute: :redeemable_value, orderable: false, width: "5%"},
    {attribute: :redeemable_points, orderable: false, width: "5%"},
    {attribute: :total_deposits, orderable: false, width: "5%"},
    {attribute: :total_redeemed, orderable: false, width: "5%"},
    {attribute: :currencies, orderable: false, width: "10%"},
    {attribute: :status, orderable: false, width: "5%"}
  ].freeze

  def default_order
    "[[ 1, \"desc\" ]]"
  end

  def namespace
    "rewards_funds_accounts"
  end

  def serializer
    RewardsFundsAccountSerializer
  end

  def server_side_export
    false
  end

  private

  def all_records
    Rewards::FundsAccount.primary
      .joins(:company)
      .includes(:company)
  end

  def filtered_records
    accounts = all_records

    if search_query.present?
      accounts = accounts.where("companies.domain like :search", search: "%#{params[:search][:value]}%")
    end

    accounts = accounts.order(sort_columns_and_directions)
    # switched to the #paginate syntax over `page(page).per_page(per_page)` because
    # that syntax doesn't work for arrays which are necessary for testing (mocks)
    accounts = accounts.paginate(page: page, per_page: per_page)

    accounts
  end

  class RewardsFundsAccountSerializer < BaseDatatableSerializer
    attributes :domain, :balance, :currencies, :redeemable_points, :redeemable_value, :name,
               :total_deposits, :total_redeemed, :status

    def account
      object
    end

    def calculators
      @calculators ||= catalogs.map { |c| Rewards::RewardPointCalculator.new(company, c) }
    end

    def catalogs
      company.catalogs
    end

    def currencies
      catalogs.map(&:currency).join(", ")
    end

    def company
      account.company
    end

    def domain
      company.domain
    end

    def name
      company.name
    end

    def redeemable_points
      calculators.inject(0) { |sum, c| sum + c.awarded_unredeemed_points }
    end

    def redeemable_value
      calculators.inject(0) { |sum, c| sum + c.awarded_unredeemed_value }
    end

    def status
      company.program_enabled ? 'Active' : 'Disabled'
    end

    def total_deposits
      Rewards::FundsTxn.joins(:funds_account).where(funds_account_id: account.id).where(txn_type: "credit").sum(:amount)
    end

    def total_redeemed
      Rewards::FundsTxn.joins(:funds_account).where(funds_account_id: account.id).where(txn_type: "debit").sum(:amount)
    end
  end
end
