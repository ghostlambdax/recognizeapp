module DelayedJobHelper
  # FIXME: this module needs serious help
  #        need better way to support objects that are subclassed off ProgressJob::Base
  def dj_method_name(job)
    #Note: method_name is not available for active job
    if job.payload_object.is_a?(ApplicationHelper::ACTIVE_JOB_DJ_CLASS)
      return
    else
      dj_use_signature?(job) ?
        job.payload_object.method_name :
        job.handler.match(/method_name:(.*)\n/)[1].gsub(':','').strip
    end
  rescue => e
    e.to_s
  end

  def dj_object_label(job)
    if job.payload_object.is_a?(ApplicationHelper::ACTIVE_JOB_DJ_CLASS)
      klass = job.payload_object.job_data["job_class"]
    else
      if dj_use_signature?(job)
        klass = job.payload_object.class
      else
        klass_or_obj = job.handler.match(/Performable.*\nobject:(.*)\n/)[1]
        if klass_or_obj.match(/ruby\/class/)
          klass = klass_or_obj.gsub('!ruby/class ', '').gsub('\'','').strip
        else
          klass = klass_or_obj.gsub('!ruby/object:', '').gsub('\'','').strip
          id_attr = job.handler.match(/attributes:\n(.*)\n/)
          id = id_attr ? id_attr[1].strip.split(":")[1].strip : nil
        end
      end
    end

    return id ? "#{klass}:#{id}" : klass
  rescue => e
    e.to_s
  end

  def dj_args(job)
    if job.payload_object.is_a?(ApplicationHelper::ACTIVE_JOB_DJ_CLASS)
      job.payload_object.job_data["arguments"]
    else
      dj_use_signature?(job) ?
        job.args || job.signature :
        job.handler.match(/args:(.*)\n/m)[1].strip
    end
  rescue => e
    e.to_s
  end

  def dj_queue(job)
    job.queue
  end

  def dj_use_signature?(job)
    !job.handler.match(/Performable.*\nobject:(.*)\n/)
  end
end