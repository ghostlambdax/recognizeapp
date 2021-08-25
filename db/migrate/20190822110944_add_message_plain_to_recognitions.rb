class AddMessagePlainToRecognitions < ActiveRecord::Migration[5.0]
  include ActionView::Helpers::SanitizeHelper

  def change
    add_column :recognitions, :message_plain, :text

    reversible do |dir|
      dir.up do
        Recognition.reset_column_information
        set_without_tags = Recognition.where("message NOT like '%<%' OR message NOT like '%>%'")
        set_without_tags.update_all("message_plain = message")

        set_with_tags = Recognition.where("message like '%<%' AND message like '%>%'")
        set_with_tags.find_each do |recognition|
          begin
            plain_message = strip_tags(recognition.message)
            recognition.update_column :message_plain, plain_message
          rescue => e
            puts "Migration: Caught error when updating recognition ##{recognition.id}. Exception: #{e})"
          end
        end
      end
    end
  end
end
