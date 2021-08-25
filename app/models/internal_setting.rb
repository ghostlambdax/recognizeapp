# This model is meant to store sitewide settings
# that aren't a good fit for environment variables
# such as values that we might want to switch without
# having to do a deployment
#
# This is essentially simple site-widde key/value store
# code that uses these settings should be defensive against
# null values and null keys
class InternalSetting < ActiveRecord::Base

  validates :key, uniqueness: { case_sensitive: true }

  def self.close_sequence_api_key
    where(key: 'close_sequence_api_key').first&.value
  end

  CLOSE_SETTINGS = %I(
    close_sequence_api_key
    close_sequence_id
    close_sequence_sender_account_id
    close_sequence_sender_email
    close_sequence_sender_name
  )
  def self.close_settings
    where(key: CLOSE_SETTINGS).inject(Hashie::Mash.new){|mash, setting| mash[setting.key] = setting.value;mash}
  end
end
