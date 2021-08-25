# frozen_string_literal: true

module AccountsSpreadsheetImport
  class HeaderAlias
    attr_reader :expected_header, :alias_header, :opts

    DEFAULT_OPTS = { strip: true, ignore_case: true }.freeze

    DEFAULT_OPTIONAL_HEADER_IDENTIFIER = "(optional)"

    HEADER_ALIAS_MAP = {
      "employee id" => {
        attribute_identifier: :employee_id,
        aliases: ["employeeid", "id"],
        can_have_optional_header_identifier: true,
        optional_header_identifier_aliases: [DEFAULT_OPTIONAL_HEADER_IDENTIFIER]
      },
      "email" => {
        attribute_identifier: :email,
        aliases: ["email address"],
        can_have_optional_header_identifier: false
      },
      "first name" => {
        attribute_identifier: :first_name,
        aliases: ["first", "given", "given name"],
        can_have_optional_header_identifier: false
      },
      "last name" => {
        attribute_identifier: :last_name,
        aliases: ["last", "surname"],
        can_have_optional_header_identifier: false
      },
      "job title" => {
        attribute_identifier: :job_title,
        aliases: ["job", "title"],
        can_have_optional_header_identifier: true,
        optional_header_identifier_aliases: [DEFAULT_OPTIONAL_HEADER_IDENTIFIER]
      },
      "phone" => {
        attribute_identifier: :phone,
        aliases: ["phone number", "mobile number", "work number", "mobile", "work phone"],
        can_have_optional_header_identifier: true,
        optional_header_identifier_aliases: [DEFAULT_OPTIONAL_HEADER_IDENTIFIER]
      },
      "team" => {
        attribute_identifier: :team_names,
        aliases: ["teams", "company team", "company teams"],
        can_have_optional_header_identifier: true,
        optional_header_identifier_aliases: [DEFAULT_OPTIONAL_HEADER_IDENTIFIER]
      },
      "roles" => {
        attribute_identifier: :role_names,
        aliases: ["role", "company role", "company roles"],
        can_have_optional_header_identifier: true,
        optional_header_identifier_aliases: [DEFAULT_OPTIONAL_HEADER_IDENTIFIER]
      },
      "start date mm/dd/yyyy" => {
        attribute_identifier: :start_date,
        aliases: ["start date", "start", "hire date"],
        can_have_optional_header_identifier: true,
        optional_header_identifier_aliases: [DEFAULT_OPTIONAL_HEADER_IDENTIFIER]
      },
      "birthday mm/dd" => {
        attribute_identifier: :birthday,
        aliases: ["birthday"],
        can_have_optional_header_identifier: true,
        optional_header_identifier_aliases: [DEFAULT_OPTIONAL_HEADER_IDENTIFIER]
      },
      "manager email" => {
        attribute_identifier: :manager_email,
        aliases: ["manager"],
        can_have_optional_header_identifier: true,
        optional_header_identifier_aliases:
          [
            DEFAULT_OPTIONAL_HEADER_IDENTIFIER,
            "(optional - must be users in Recognize)"
          ]
      },
      "display name" => {
        attribute_identifier: :display_name,
        aliases: ["display name"],
        can_have_optional_header_identifier: true,
        optional_header_identifier_aliases: [DEFAULT_OPTIONAL_HEADER_IDENTIFIER]
      },
      "country" => {
        attribute_identifier: :country,
        aliases: ["country"],
        can_have_optional_header_identifier: true,
        optional_header_identifier_aliases: [DEFAULT_OPTIONAL_HEADER_IDENTIFIER]
      },
      "department" => {
        attribute_identifier: :department,
        aliases: ["department"],
        can_have_optional_header_identifier: true,
        optional_header_identifier_aliases: [DEFAULT_OPTIONAL_HEADER_IDENTIFIER]
      },
      "locale" => {
        attribute_identifier: :locale,
        aliases: ["locale"],
        can_have_optional_header_identifier: true,
        optional_header_identifier_aliases: [DEFAULT_OPTIONAL_HEADER_IDENTIFIER]
      }
    }.freeze

    def self.matches?(expected_header, alias_header, opts = {})
      header_alias = new(expected_header, alias_header, opts)
      header_alias.matches?
    end

    def initialize(expected_header, alias_header, opts = {})
      @opts = opts.reverse_merge! DEFAULT_OPTS
      @expected_header = normalize_expected_header(expected_header)
      @alias_header = normalize_alias_header(alias_header)
    end

    def matches?
      return true if expected_header == alias_header
      return true if alias_in_map?

      false
    end

    def aliases
      HEADER_ALIAS_MAP[expected_header][:aliases]
    end

    def alias_in_map?
      aliases.include?(alias_header)
    end

    def normalize_as_per_opts(string)
      string = string.to_s
      string = string.strip if opts[:strip]
      string = string.downcase if opts[:ignore_case]
      string
    end

    def normalize_expected_header(string)
      normalize_as_per_opts(string)
    end

    def normalize_alias_header(string)
      string = normalize_as_per_opts(string)
      string = remove_bom_character_if_present(string)
      string = remove_optional_header_identifier_if_present(string)
      string
    end

    def optional_header_identifier_aliases
      HEADER_ALIAS_MAP[expected_header][:optional_header_identifier_aliases]
    end

    def can_have_optional_header_identifier?
      HEADER_ALIAS_MAP[expected_header][:can_have_optional_header_identifier]
    end

    def remove_optional_header_identifier_if_present(alias_header)
      return alias_header unless can_have_optional_header_identifier?

      # A header can have multiple optional header identifier strings.
      # For example:
      #   "Manager" header, in sample spreadsheet, has "(optional - must be users in Recognize)" appended to it.
      #    The header can also just come in with "(optional)" appended to it, like the rest of the optional headers.
      optional_header_identifier_aliases.each do |optional_header_identifier_alias|
        normalized_optional_header_identifier_alias = normalize_as_per_opts(optional_header_identifier_alias)
        alias_header = alias_header.sub(normalized_optional_header_identifier_alias, "")
      end
      # An optional header identifier might have a space prepended to it. Eg: "Employee Id (Optional)". Remove it.
      alias_header.strip
    end

    # https://www.pluralsight.com/guides/headaches-of-utf-8-bom
    # BOM, if present, is at the beginning of the file, i.e. at the first column first row of the sheet(off CSV).
    def remove_bom_character_if_present(alias_header)
      return alias_header if alias_header[0].ascii_only?

      alias_header[0] = ''
      alias_header
    end

    class << self
      def optional_header_identifier
        DEFAULT_OPTIONAL_HEADER_IDENTIFIER
      end

      # Optional, but, if present, it is expected to be the first column.
      def employee_id_header
        "Employee id"
      end

      def manager_email_header
        "Manager Email(optional - must be users in Recognize)"
      end

      def supported_headers
        HEADER_ALIAS_MAP.keys.map(&:humanize)
      end

      # Returns an array of hash with following signature (example).
      #   {
      #     expected_header: "phone"
      #     alias_headers: ["phone number", "mobile number", "work number", "mobile", "work phone"]
      #     user_attribute: :phone
      #   }
      def headers_and_user_attribute_map_array
        HEADER_ALIAS_MAP.map do |key, value|
          {
            expected_header: key,
            alias_headers: value.fetch(:aliases),
            user_attribute: value.fetch(:attribute_identifier)
          }
        end
      end

      def header_for_user_attribute(user_attribute)
        headers_and_user_attribute_map_array.find do |headers_and_user_attribute_map|
          headers_and_user_attribute_map.fetch(:user_attribute) == user_attribute
        end&.fetch(:expected_header)
      end

      def user_attribute_for_header(header)
        alias_header = header
        matching_map = headers_and_user_attribute_map_array.find do |headers_and_user_attribute_map|
          possible_expected_header = headers_and_user_attribute_map.fetch(:expected_header)
          self.new(possible_expected_header, alias_header).matches?
        end
        matching_map.fetch(:user_attribute)
      end
    end
  end
end
