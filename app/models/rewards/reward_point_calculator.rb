module Rewards
  class RewardPointCalculator
    attr_reader :company, :catalog

    def initialize(company, catalog = nil)
      @company = company
      @catalog = catalog || company.principal_catalog
    end

    def awarded_unredeemed_points
      @awarded_unredeemed_points ||= begin
        company.users.not_disabled.inject(0) do |sum, user|
          sum + user.redeemable_points
        end
      end
    end

    def awarded_unredeemed_value
      monetize(awarded_unredeemed_points / points_to_currency_ratio)
    end

    def economy_monetary_value
      monetize(economy_points_value / points_to_currency_ratio)
    end

    def economy_points_value
      @economy_points_value ||= begin
        company.company_badges.recognitions.inject(0) do |sum, badge|
          possible_points = badge.possible_points_per_reset_interval
          unless possible_points == Float::INFINITY
            sum += possible_points
          end
          sum
        end
      end
    end

    def in_deficit?
      points_deficit < 0
    end

    def monetary_deficit
      monetize(points_deficit / points_to_currency_ratio)
    end

    def points_deficit
      reward_points_balance - economy_points_value
    end

    def points_left_to_be_awarded
      economy_points_value - awarded_unredeemed_points
    end


    def points_to_currency_ratio
      catalog&.points_to_currency_ratio
    end

    def redeemable_points_monetary_value
      monetize(awarded_unredeemed_points / points_to_currency_ratio)
    end

    def redeemed_points_value
      monetize(redeemed_points / points_to_currency_ratio)
    end

    def reward_monetary_balance(opts = {})
      val = company.primary_funding_account.balance
      val = exchange_money_from_funding_balance(val)
      val = monetize(val) if opts[:money]
      val
    end

    def reward_points_balance
      (reward_monetary_balance * points_to_currency_ratio).to_i
    end

    def redeemed_points
      company.redemptions.by_catalog(catalog).sum(:points_redeemed)
    end

    def reward_monetary_balance_currency
      catalog&.currency || Rewards::Currency::RECOGNIZE_BASE_CURRENCY
    end

    private

    def monetize(val)
      Money.from_amount(val, self.catalog.currency)
    end

    def exchange_money_from_funding_balance val
      base_currency = Rewards::Currency::RECOGNIZE_BASE_CURRENCY
      currency = catalog&.currency || base_currency
      if currency != base_currency
        val = Money.from_amount(val, base_currency).exchange_to(catalog.currency).to_f
      end
      val
    end
  end
end
