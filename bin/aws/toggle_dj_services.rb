#!/usr/bin/env ruby
require 'json'
require 'shellwords'
require 'byebug'

class DjService
  attr_reader :env, :count

  POSSIBLE_ENVS = %w(patagonia staging production)

  def initialize(env)
    @env = env
    raise "No environment specified! Usage: bin/aws/sync_cron.rb [patagonia|staging|production]" unless POSSIBLE_ENVS.include?(env)
  end

  def exec_cmd(cmd)
    puts "Executing: #{cmd}"
    JSON.parse(`#{cmd}`)
  end

  def update(count)
    raise "Invalid count: #{count}" unless  /\A[+-]?\d+\z/ === count
    @count = count.to_i

    services = list_services
    # services = [services[0]]
    services.each do |svc|
      update_service(svc)
    end    
  end

  def list_services
    cmd = "aws ecs list-services --cluster=ecs-#{env}"
    services = exec_cmd(cmd)["serviceArns"].select{|arn| arn.match(/delayjob/)}
  end

  def update_service(svc)
    # puts "Updating #{svc} to #{count} tasks"
    exec_cmd("aws ecs update-service --cluster=ecs-#{env} --service=#{svc} --desired-count=#{count}")
  end
end
DjService.new(ARGV[0]).update(ARGV[1])
