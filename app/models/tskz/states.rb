module Tskz
  class States
    include IdNameMethods
    DATA =  [
      [ PENDING = 0, :pending, nil],
      [ RESOLVED = 1, :resolved, nil],
      [ APPROVED = 2, :approved, nil],
      [ DENIED = 3, :denied, nil]
    ]

    def self.approved
      APPROVED
    end

    def self.denied
      DENIED
    end
  end
end