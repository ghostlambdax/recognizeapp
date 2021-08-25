module BulkRecognition
  class Validator
    include ActiveModel::Validations

    validate :valid_badges

    delegate :options, :schema, :company, :file_parser, to: :@bulk_base

    def initialize(bulk_base)
      @bulk_base = bulk_base
    end

    private

    def valid_badges
      valid_badge_names = company.badges.map(&:short_name).map(&:downcase)

      file_parser.data.each_with_index do |row, index|
        line = "(Line #{index + 2})"
        next if row.all? { |i| i.to_s.blank? || i.nil? }

        badge = row[schema[:badge]]&.strip
        err_msg = if badge.blank?
          "Badge name cannot be empty. #{line}"
        elsif valid_badge_names.exclude?(badge.downcase)
          "#{badge} is not a valid badge name. #{line}"
        end
        self.errors.add(:base, err_msg) if err_msg.present?
      end
    end
  end
end
