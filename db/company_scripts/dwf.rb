mappings = FactoryBot.build(:dwf_custom_field_mappings)
suffix = Rails.env.development? ? ".not.real.tld" : ""
c = Company.where(domain: "dwf.law"+suffix).first
mappings.each_with_index do |(name, provider_key), index|
  key = "custom_field#{index}"
  c.custom_field_mappings.set(key, name, provider_key)
end

c.settings.update_column(:sync_custom_fields, true)

# Test line
# c.admin_sync_user.microsoft_graph_client.user(c.users.where.not(microsoft_graph_id: nil).last.microsoft_graph_id, c.custom_field_mappings.microsoft_graph_query_attributes))

# Test read custom field data from users
# c.users.map{|u| (0..9).map{|i| u.send("custom_field#{i}")}}
