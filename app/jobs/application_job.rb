class ApplicationJob < ActiveJob::Base 

  def serialize
    super.tap do |hash|
      # arguments are the ActiveJob arguments sent to #perform
      hash = named_job_arguments(arguments, hash)
      hash[:argument_keys] = hash.keys
    end
  end

  # This method will automatically set instance variables for 
  # the keys of the arguments set in #arguments_to_serialize_for_signature
  def deserialize(job_data)
    argument_keys = job_data[:argument_keys]
    argument_keys.each do |k|
      # set instance variables like @company_id
      instance_variable_set("@#{k}", job_data[k])
    end
    super
  end

  # return a hash of key/values for the arguments to serialize
  # in the ApplicationJob
  # Example implementation: 
  # # def arguments_to_serialize_for_signature(job_args, hash)
  # #  datatable = job_args[0]
  # #  hash["company_id"] = datatable.company.id
  # #  hash["datatable_class"] = datatable.class.to_s
  # #  hash["current_user_id"] = datatable.current_user.id
  # #  return hash
  # # end
  # This will explicitly save company_id, datatable_class, and current_user_id in named keys
  # upon serialization, and then set them as instance variables with those values upon deserialization
  # So, jobs will have access to these in #perform and will also have access to them for automatic #signature
  def named_job_arguments(job_args, hash)
    raise "Must be implemented by subclasses!"
  end
end
