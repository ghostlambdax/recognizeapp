module Rewards
  class FundingSources
    include IdNameMethods
    # check, wire, credit card(stripe), manual
    DATA =  [
      [ MANUAL = 1, :manual, "Manual credit"],
      [ WIRE = 2, :wire, "Wire"],
      [ CHECK = 3, :check, "Check"],
      [ CREDIT = 4, :credit, "Credit card"],
    ]
  end
end