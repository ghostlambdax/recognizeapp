# bin/rails r `Utility::BadgeImport.new(Company.where(domain: 'livebouldercreek.com.not.real.tld').first, 'tmp/BCN_Recognize_Badge List.csv', 'tmp/BCN_Recognize Badges_06JUL2018/').import"
# Utility::BadgeImport::SingleBadgeImport.new(Company.where(domain: 'livebouldercreek.com.not.real.tld').first, ['BCN_Critical-Thinking.png', 'Critical Thinking', 'Badge Description'], 'tmp/BCN_Recognize Badges_06JUL2018/').import!

# ADJUST SCHEMA:
# opts = {file_name_index: 0, badge_name_index: 1, badge_description_description: 5}

module Utility
  class BadgeImport
    attr_reader :company, :data_csv_path, :image_folder_path, :badge_rows, :opts
    def initialize(company, data_csv_path, image_folder_path, opts = {})
      @company = company
      @data_csv_path = data_csv_path
      @image_folder_path = image_folder_path
      @badge_rows = load_data
      @results = {success: [], fail: []}
      @opts = opts
    end

    def import
      load_data
      import_badges
    end

    def import_badges
      badge_rows.each do |badge_row|
        puts "Processing: #{badge_row}"
        importer = SingleBadgeImport.new(company, badge_row, image_folder_path, opts)
        importer.import!
        importer.success? ? @results[:success] << importer : @results[:fail] << importer
        puts "Badge import #{importer.success? ? 'Succeeded' : "Failed: #{importer.error_messages}"}"
      end
    end

    def load_data
      CSV.readlines(data_csv_path)
    end

    class SingleBadgeImport
      attr_reader :company, :badge_row, :image_folder_path, :opts, :indices

      def initialize(company, badge_row, image_folder_path, opts = {})
        @company = company
        @badge_row = badge_row
        @image_folder_path = image_folder_path
        @errors = []
        @opts = opts
      end

      def badge_file_name
        badge_row[indices[:badge_file_name]]
      end

      def badge_name
        badge_row[indices[:badge_name]]
      end

      def badge_description
        badge_row[indices[:badge_description]]
      end

      def error_messages
        @errors.to_sentence
      end

      def indices
        {
          badge_file_name: (opts[:file_name_index] || 0),
          badge_name: (opts[:badge_name_index] || 1),
          badge_description: (opts[:badge_description_description] || 5)
        }
      end

      def image_exists?
        images_in_folder.include?(badge_file_name)
      end

      def image_folder
        @image_folder ||= File.join(Rails.root, image_folder_path)
      end

      def images_in_folder
        Dir.entries(image_folder)
      end

      def import_badge
        badge = Badge.find_or_initialize_by(company_id: company.id, short_name: badge_name)
        badge.description = badge_description
        badge.image = badge_image_file
        unless badge.save
          badge.errors.full_messages.each do |e|
            @errors << e
          end
        end
      end

      def import!
        begin
          if image_exists?
            import_badge
          else
            @errors << "Image doesn't exist - #{badge_image_file.inspect}"
          end
        rescue => e
          @errors << e
        end
      end

      def success?
        @errors.blank?
      end

      def badge_image_file
        Rails.root.join(image_folder_path, badge_file_name).open
      end
    end
  end
end