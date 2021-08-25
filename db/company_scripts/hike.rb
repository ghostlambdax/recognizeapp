c = Company.where(domain: "hike.in").first
group_counts = c.sent_recognitions.group(:viewer).count
workplace_recognitions = c.sent_recognitions.where(viewer: "fb_workplace").group(:post_to_fb_workplace).count

results = {}
results["bot_tagging_flow_recognitions"] = workplace_recognitions[nil]
results["webview_recognitions_posted_back_to_workplace"] = workplace_recognitions[true]
results["webview_recognitions_private"] = workplace_recognitions[false]
results["direct_on_recognize"] = group_counts[nil]
results.each{|k,v| puts "#{k.humanize}: #{v}"}