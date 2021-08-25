# Custom Label examples
# c is any company object
# run all examples or only a few in a console to test 
c.labels ||= {}
c.labels[:recognition] ||= {}
c.labels[:welcome_page] ||= {}
c.labels[:badges_index] ||= {}

c.labels[:default_email_from] = "Kudos"
c.labels[:recognition_email_subject] = "%{name} sent you a kudos"
c.labels[:recognition_tags] = "Customers"
c.labels[:task_tags] = "Categories"
c.labels[:top_users] = "Top all stars"

c.labels[:recognition][:new_recognition_recipient] = "I'd like to send a kudos to"
c.labels[:recognition][:view_your_recognition] = "View your kudos"

c.labels[:welcome_page][:tagline] = "Send a kudos to a well deserving teammate or team"
c.labels[:welcome_page][:description] = ""
c.labels[:welcome_page][:recognize_button] = "Send a kudos"

c.labels[:badges_index][:welcome] = "Kudos badges"

# save it
# c.save
