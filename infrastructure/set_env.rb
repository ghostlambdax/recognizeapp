#!/usr/bin/env ruby
require 'aws-sdk-ssm'
parameter_path_prefix = ARGV[0]
filename = ARGV[1]

next_token = nil
File.open("ssm_source", "w+") do |f|
  loop do
    response = Aws::SSM::Client.new.get_parameters_by_path(
      path: parameter_path_prefix, 
      recursive: true, 
      with_decryption: true, 
      next_token: next_token)

    next_token = response.next_token
    if response.parameters.empty?
      break
    end

    response.parameters.each do |param|
        # ENV[param["name"].split("/").last] = param["value"]
        f << "export #{param["name"].split("/").last}=\"#{param["value"]}\"\n"
      end  

    if next_token.nil?
      break
    end    
  end
end
