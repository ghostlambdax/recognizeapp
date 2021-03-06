class ContactList < ApplicationRecord
  belongs_to :user

  def contacts=(new_contacts)
    self.contacts_raw = JSON.dump(new_contacts)
    self.user.refresh_cached_contacts!
  end

  # key/value pair of email address => name/label for that contact
  def contacts
    contacts_raw.present? ? JSON.parse(contacts_raw) : {}
  end

end
