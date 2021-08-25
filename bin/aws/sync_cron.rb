#!/usr/bin/env ruby
require 'json'
require 'shellwords'

class CronSyncer
  attr_reader :env, :account_id, :region

  POSSIBLE_ENVS = %w(patagonia staging production everest)

  def initialize(env)
    @env = env
    @account_id = ENV['AWS_ACCOUNT_ID'] #"545781544991" 
    @region = ENV['AWS_REGION'] || ENV['AWS_DEFAULT_REGION'] #"us-west-1"
    puts "Syncing cron for #{account_id}:#{region}"
    raise "No environment specified! Usage: bin/aws/sync_cron.rb [everest|patagonia|staging|production]" unless POSSIBLE_ENVS.include?(env)
  end

  def sync!
    clear_rules
    create_rules
  end

  def create_rules
    # environments = ["patagonia", "staging", "production"]
    security_groups = get_security_groups #%w(sg-0fd56d54b80cef605)
    subnets = get_subnets #%w(subnet-0ce98c1f667725d46 subnet-009fb8eb4c6290e1e)
  
    target_json_skeleton = JSON.parse(File.read(File.dirname(__FILE__)+"/json_templates/target_json_skeleton.json"))

    cluster_arn = "arn:aws:ecs:#{region}:#{account_id}:cluster/ecs-#{env}"
    task_definition_arn = "arn:aws:ecs:#{region}:#{account_id}:task-definition/recognize-#{env}-cron-fargate"
    role_arn = "arn:aws:iam::#{account_id}:role/ecsEventsRole"

    command_template = '---command---' # will get gsub'd with actual command later
    name_template = '---name---'

    # dogwrapped_command = %Q(dogwrap -n '#{name_template}' -k $DataDogAPIKey --submit_mode all \"#{command_setup} '#{command_template}'\" && echo 'Completed #{name_template}')
    entry_template = "echo 'Starting #{name_template}'"
    exit_template = "echo 'Completed #{name_template}'"

    scheduled_task_cmd_template = %Q(infrastructure/setup_cron.sh '/recognize/$EnvironmentType/' && bash -c 'source ssm_source && bundle exec rails runner -e production \\\"#{command_template}\\\"')
    unwrapped_scheduled_task_cmd_template = %Q(echo 'Starting #{name_template}' && infrastructure/setup_cron.sh "/recognize/$EnvironmentType/" && bash -c 'source ssm_source && bundle exec rails runner -e production \"#{command_template}\"' && echo 'Completed #{name_template}')
    dogwrapped_command = %Q(dogwrap -n '#{name_template}' -k $DataDogAPIKey --submit_mode all \"echo 'Starting #{name_template}' && #{scheduled_task_cmd_template} && echo 'Completed #{name_template}'\")

    input_template = {
      containerOverrides: [
        name: "recognize-rails",
        # command: ["/bin/bash", "-c", unwrapped_scheduled_task_cmd_template] # non-dogwrap
        command: ["/bin/bash", "-c", dogwrapped_command] # dogwrap
    ]}.to_json

    output = `whenever`
    lines = output.split("\n").reject(&:empty?).reject{|l| l.match(/^\#/)}

    lines.each do |line|
      parts = line.match(/(.*)(\/bin\/bash \-l \-c)(.*)/)

      cron_expression = parts[1].split(" ")
      cron_expression.insert(4, "?")
      cron_expression = cron_expression.map{|n| n.gsub(",", "/")}
      cron_expression = cron_expression.join(" ")

      cron_line = parts[3]

      case
      when cron_line.match(/runner/)
        command = cron_line.gsub(/.*runner -e production...../, '')
        command.gsub!(/\>\>.*/, '')
        command.gsub!(/.....$/,'')
        # command.gsub!(/[!]/,'')
        id = "#{env.capitalize}-"+command.gsub(/[!]/,'').split(";").first.gsub("::",'.')[0..40]


        create_rule_cmd = %Q(aws events put-rule --name #{id.dump} --region #{region} --schedule-expression "cron(#{cron_expression})" --description #{command.dump})
        puts create_rule_cmd
        rule_result = `#{create_rule_cmd}`
        rule_result_json = JSON.parse(rule_result)
        rule_arn = rule_result_json["RuleArn"]


        json = target_json_skeleton.dup
        json["Rule"] = id

        target = json["Targets"][0]
        target["Id"] = id
        target["Arn"] = cluster_arn
        target["RoleArn"] = role_arn
        target["Input"] = input_template.gsub(command_template, command).gsub(name_template, id)

        # target["RunCommandParameters"]["RunCommandTargets"][0]["Values"][0] = 1
        # target["RunCommandParameters"]["RunCommandTargets"][0]["Key"] = 1

        ecs_params = target["EcsParameters"]
        ecs_params["TaskDefinitionArn"] = task_definition_arn
        ecs_params["TaskCount"] = 1

        network_config = ecs_params["NetworkConfiguration"]["awsvpcConfiguration"]
        network_config["SecurityGroups"] = security_groups
        network_config["Subnets"] = subnets


        json = json.to_json
        File.open("cron.json", 'w'){|f| f.write(json) }
        # scheduled_task_cmd = "aws events put-targets --region us-west-1 --cli-input-json '#{json}'"
        scheduled_task_cmd = "aws events put-targets --region #{region} --cli-input-json 'file://./cron.json'"

        puts "#{cron_expression} - #{command}"
        puts "\t#{scheduled_task_cmd}"
        puts "Result: "+`#{scheduled_task_cmd}`

      when cron_line.match(/rake/)
        raise "Command not supported #{cron_line}"
      else #raw shell command
        raise "Command not supported: #{cron_line}"
      end
    end
  end

  def clear_rules
    rules = `aws events list-rules --name-prefix=#{env.capitalize}`
    rules = JSON.parse(rules)["Rules"]
    # puts rules.map{|r| r["Name"]}
    rules.each do |rule|
      targets = `aws events list-targets-by-rule --region #{region} --rule #{rule["Name"].dump}`
      target = JSON.parse(targets)["Targets"][0]
      `aws events remove-targets --region #{region} --rule #{rule["Name"].dump} --ids #{target["Id"].dump}` if target
      `aws events delete-rule --region #{region} --name #{rule["Name"].dump}`
    end
  end

  def get_security_groups
    @security_groups ||= begin
      [outputs.detect{ |output| output['OutputKey'] == 'ECSSecurityGroup' }['OutputValue']]
    end
  end

  def get_subnets
    @subnets ||= begin
      subnet1 = outputs.detect{ |output| output['OutputKey'] == 'PrivateSubnet1' }['OutputValue']
      subnet2 = outputs.detect{ |output| output['OutputKey'] == 'PrivateSubnet2' }['OutputValue']
      [subnet1, subnet2]
    end
  end

  def outputs
    @outputs ||= JSON.parse(`aws cloudformation describe-stacks --stack-name=recognize-$EnvironmentType --query "Stacks[0].Outputs[]" --output json`)
  end
end
CronSyncer.new(ARGV[0]).sync!


