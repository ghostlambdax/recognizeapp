module BulkRecognition
  class Recognizer

    include ActionView::Helpers::SanitizeHelper
    include ActionView::Helpers::TextHelper

    attr_reader :row, :status, :remarks

    delegate :schema, :email_suffix, :options, :company, to: :@bulk_base

    def initialize(row, bulk_base)
      @row = row
      @bulk_base = bulk_base
      # default for success
      @remarks = "Completed without failure"
      @status = "Success"
    end

    def recognize
      sender, badge, point_value = parse_raw_column_data(column_map)
      badge.points = point_value.to_i if point_value
      validate_and_recognize_users(sender, badge)
    end

    def column_map
      {
        recipient_emails_or_phones: row[schema[:recipient_email_or_phone]].to_s,
        sender_email_field: row[schema[:sender_email]].to_s,
        badge_field: row[schema[:badge]].to_s,
        message_field: row[schema[:message]].to_s,
        point_value_field: row[schema[:point_value]].to_s
      }
    end

    def parse_raw_column_data(column_mapped_hash)
      @recipient_emails_or_phones = column_mapped_hash[:recipient_emails_or_phones].split(",").map(&:strip).map(&:downcase).map { |r| r.match(/@/) ? (r + email_suffix) : r }
      @sender_email = column_mapped_hash[:sender_email_field].strip + email_suffix
      @badge_name = column_mapped_hash[:badge_field].strip
      @message = column_mapped_hash[:message_field].strip

      badge = company.badges.detect { |b| b.short_name.downcase == @badge_name.downcase }

      # If anniversary badge, sender_email in the row is ignored!
      # and we force system user as per normal anniversary recognitions
      # NOTE: We could theoretically enhance this to permit anniversaries
      #       to be sent by an actual user (via flag or row data), but that may cause other issues
      #       if we wanted to officially support that and needed to do data cleanup
      #       So, let's avoid it for now.
      sender = if badge&.is_anniversary?
        User.system_user
      else
        company.users.find_by(email: @sender_email)
      end
      point_value = column_mapped_hash[:point_value_field].to_s&.tr(',', '').presence
      [sender, badge, point_value]
    end

    def validate_and_recognize_users(sender, badge)
      options[:soft_save] = true
      message = options[:input_format] == 'html' ? sanitize_and_format_message(@message) : @message
      recognition = Recognition.create_custom(sender, @recipient_emails_or_phones, badge, message, options, company)
      unless recognition.valid?
        @remarks = generate_proper_validation_error_message(recognition.errors)
        @status = "Failure"
      end
    end

    def sanitize_and_format_message(message)
      allowed_tags, allowed_attributes = Recognition.allowed_html_tags_and_attributes
      opts = { tags: allowed_tags, attributes: allowed_attributes}
      message = sanitize(message, opts)

      simple_format(message, {}, sanitize: false)
    end

    def generate_proper_validation_error_message(errors)
      errors.messages.each_with_object("") do |(err_key, err_msgs), full_message|
        err_msgs.each do |err_msg|
          if err_msg.is_a?(String)
            full_message << format_error_messages(err_key, err_msg)
          # for nested error messages
          elsif err_msg.is_a?(Hash)
            err_msg.each do |nested_err_key, nested_err_msgs|
              nested_err_msgs.each do |nested_err_msg|
                full_message << format_error_messages(nested_err_key, nested_err_msg)
              end
            end
          end
          # add new line to separate multiple errors except for the last error message
          full_message << "\n" unless err_key == errors.messages.keys.last && err_msg == err_msgs.last
        end
      end
    end

    def format_error_messages(err_key, err_msg)
      if err_msg.starts_with?("^")
        err_msg.delete_prefix("^")
      else
        if I18n.exists?("activerecord.attributes.recognition.#{err_key}", :en)
          [I18n.t("activerecord.attributes.recognition.#{err_key}"), err_msg].join(" ")
        elsif err_key == :sender_id && err_msg == "can't be blank"
          if email_suffix.present?
            "Cannot find sender. You probably forgot to remove the email suffix, \"#{email_suffix}\"."
          else
            "Cannot find sender."
          end
        else
          [err_key.to_s.humanize, err_msg].join(" ")
        end
      end
    end

    def succeeded?
      @status == "Success"
    end

    def data_to_log
      [@status, "[Bulk Recognition] Status: #{@status}, Remarks: \"#{@remarks}\" \n" \
        "Attributes: [ Sender email: #{@sender_email}, Recipient email: #{@recipient_emails_or_phones}, Badge: #{@badge_name}, Message: \"#{@message}\" ]"]
    end
  end
end
