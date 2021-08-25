require 'aws-sdk-ecs'
class CloudDeploy
  attr_reader :account, :region

  def self.register_task_definition(task_definition_family, image_tag, opts = {})
    new(opts).register_task_definition(task_definition_family, image_tag)
  end

  def initialize(opts = {})
    @account = opts[:account] || ENV['AWS_ACCOUNT_ID']
    @region = opts[:region] || ENV['AWS_DEFAULT_REGION']
  end

  def register_task_definition(task_definition_family, image_tag)
    puts "Registering task definition for family: (#{task_definition_family}) image to (#{image_tag})"
    task_definition = ecs.describe_task_definition(task_definition: task_definition_family).task_definition
    task_definition.container_definitions.each do |cd|
      repo,old_image_tag = cd.image.split(":")
      new_image_tag = "#{repo}:#{image_tag}"
      puts "Created new image tag: #{new_image_tag}"
      cd.image = new_image_tag
    end
    puts "Registering new task def with container defs: #{task_definition.container_definitions}"
    ecs.register_task_definition(family: task_definition, container_definitions: task_definition.container_definitions)
  end

  private
  def ecs
    Aws::ECS::Client.new(region: region)
  end
end
