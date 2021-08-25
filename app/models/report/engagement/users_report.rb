module Report
  module Engagement
    # this is an engagement report of a set of users, can be any set, such as managers
    class UsersReport < Base
      attr_reader :users

      def self.of_managers(company, interval, opts={})
        managers = ::User.active.where(id: ::User.select('users.manager_id').where(company_id: company.id))
        new(company, managers, interval, opts)
      end

      def initialize(company, users, interval, opts={})
        @users = users
        super(company, interval, opts)
      end

      def sent_recognition_count
        all_recognitions.where(sender_id: users.select(:id)).count
      end
    end
  end
end