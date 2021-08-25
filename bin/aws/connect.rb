#!/usr/bin/env ruby
require 'json'
require 'byebug'
cluster = ARGV[0]
container_instances = JSON.parse(`aws ecs list-container-instances --cluster #{cluster} |jq`)["containerInstanceArns"]
container_instances_metadata = JSON.parse(`aws ecs describe-container-instances --cluster #{cluster} --container-instances #{container_instances.join(' ')}|jq`)["containerInstances"]
target_map = container_instances_metadata.inject({}){|map, cim| map[cim["containerInstanceArn"]] = cim["ec2InstanceId"]; map}

tasks = JSON.parse(`aws ecs list-tasks --cluster #{cluster} |jq`)["taskArns"]
tasks_metadata = JSON.parse(`aws ecs describe-tasks --cluster #{cluster} --tasks #{tasks.join(' ')} |jq`)["tasks"]


final_map = tasks_metadata.map do |task|
  ec2InstanceId = target_map[task["containerInstanceArn"]]
  # [ec2InstanceId, task["group"], task['overrides'], task["containers"].map{|c| c["containerArn"]}.join(",")]
  [ec2InstanceId, task["group"]]
end
puts final_map.map{|i| i.join(' ')}
print "Run this on the instance: \n\t"
puts %Q(aws ssm start-session --target <target>)
print "\t"
puts %Q(curl -s http://localhost:51678/v1/tasks |jq ".Tasks[] .Containers[] | [.DockerName, .DockerId]")
