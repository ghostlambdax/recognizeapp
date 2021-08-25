#!/usr/bin/env ruby
require 'aws-sdk-ecs'
require 'aws-sdk-autoscaling'
# require 'byebug'

ecs = Aws::ECS::Client.new

cluster = ARGV[0] #"everest"
cluster_name = "ecs-#{cluster}"
data = ecs.list_container_instances(cluster: cluster_name)
container_instance_ids = data.container_instance_arns
data = ecs.describe_container_instances(cluster: cluster_name, container_instances: container_instance_ids)
has_available_instance_for_deploy = false

# We could check resources, but for now, do it coarse grained
# and simply check that we have a whole instance dedicated for deploying a task
data.container_instances.each do |ci|
  has_available_instance_for_deploy ||= true if ci.running_tasks_count.to_i == 0
end
puts "Has container instances to deploy? #{has_available_instance_for_deploy}"

unless has_available_instance_for_deploy
  puts "There are no available instances with which to deploy to"
  puts "Will attempt to kick desired capacity on ASG up a notch"
  # no available instances
  # so nudge the ASG
  puts "Getting the capacity provider: "
  cps = ecs.describe_capacity_providers(capacity_providers: ["#{cluster}-recognize-asg"])
  cp = cps.capacity_providers[0]
  puts "CP: #{cp}"
  asg_arn = cp.auto_scaling_group_provider.auto_scaling_group_arn
  puts "ASG ARN: #{asg_arn}"

  asg_client = Aws::AutoScaling::Client.new
  asg = asg_client.describe_auto_scaling_groups.auto_scaling_groups.detect{|a| a.auto_scaling_group_arn == asg_arn}
  asg_name = asg.auto_scaling_group_name
  puts "ASG name: #{asg_name}"

  current_desired_capacity = asg.desired_capacity
  new_capacity = current_desired_capacity + 1
  puts "Was: #{current_desired_capacity}, Will be: #{new_capacity}"
  response = asg_client.update_auto_scaling_group(auto_scaling_group_name: asg_name, desired_capacity: new_capacity)
  puts "Response: #{response}"
else
  puts "Nothing to do"
end
