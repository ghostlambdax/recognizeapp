#
# Note: Attribute `company_id` is deduced using the owner_id(which is user id in case of AvatarAttachment). However,
# even after running the following query, not every attachment will have an owner. This is because, if a user updates
# her profile, a new AvatarAttachment record is inserted, and the previous record that was attached to the user will
# have its `owner_id` field nil-ified.
#
def fill_company_id_in_attachments
  query = begin
    "UPDATE attachments
    SET attachments.company_id = (
      CASE type
        WHEN 'AvatarAttachment' THEN (
          SELECT users.company_id
          FROM users
          WHERE users.id = attachments.owner_id
        )
        WHEN 'BackupAttachment' THEN 1
        END
    )"
  end

  ActiveRecord::Base.connection.execute(query)
end

def do_it
  fill_company_id_in_attachments
end

# do_it
