# frozen_string_literal: true

module UserSync
  module SyncFilters
    SUPPORTED_SYNC_FILTERS = %w[equals notIn].freeze

    def filtered_users(users)
      filters = active_sync_filters
      return users if filters.blank?

      users.select do |user|
        user_matches_all_filters?(user, filters)
      end
    end

    # child provider classes can override this method to determine active filters at runtime
    # Note: The variables here are accessed implicitly - they can be accepted as args if needed for other classes
    def active_sync_filters
      company.settings.sync_filters[provider]
    end

    private

    # Main filter implementation
    #
    # Sample hash using all available filters (as of May'20):
    # { microsoft_graph:
    #   { accountEnabled: ["equals", true], mail: ["notIn", [/test/, nil]] }
    # }
    # Note: Need to update SUPPORTED_SYNC_FILTERS above when adding a new filter
    #
    def user_matches_all_filters?(user, filters)
      filters.all? do |attr, (predicate, filter_term)|
        actual_val = begin
          if user.respond_to?(:[])
            # Covers AR, Hashie, and Hash objects
            user[attr]
          elsif user.respond_to?(attr)
            # Non-AR objects (for example: AccountsSpreadsheetImport:AccountRecord) don't respond to [].
            user.send(attr)
          else
            nil
          end
        end

        case predicate
        when 'equals'
          actual_val == filter_term
        when 'notIn'
          matches_not_in_filter?(filter_term, actual_val)
        else
          raise "UserSync: Unknown filter predicate - '#{predicate}'"
        end
      end
    end

    # this filter allows single term as well as array of terms
    def matches_not_in_filter?(filter_term, actual_val)
      filter_term_array = filter_term.nil? ? [filter_term] : Array(filter_term)
      filter_term_array.none? do |filter_val|
        if [filter_val, actual_val].all? { |v| v.respond_to?(:match?) }
          # regexp and strings
          filter_val.match?(actual_val)
        elsif actual_val.is_a? Array
          # Note: Doesn't support regex check in this case.
          (actual_val & filter_term).present?
        else
          filter_val == actual_val
        end
      end
    end
  end
end
