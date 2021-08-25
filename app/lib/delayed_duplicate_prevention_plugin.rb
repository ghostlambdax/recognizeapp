require 'delayed_job'
class DelayedDuplicatePreventionPlugin < Delayed::Plugin
 
  # callbacks do |lifecycle|
  #   lifecycle.around(:invoke_job) do |job, *args, &block|
  #     # Forward the call to the next callback in the callback chain
  #     unless DuplicateChecker.duplicate?(job)
  #       block.call(job, *args)
  #     end
  #   end
  # end
 
  module SignatureConcern
    extend ActiveSupport::Concern
    
    included do
      before_validation :add_signature, on: :create
      validate :prevent_duplicate
    end

    private
    def add_signature
      self.signature = generate_signature
      self.args = self.payload_object.args if self.payload_object.respond_to?(:args)
    end

    def generate_signature
      pobj = payload_object

      if pobj.is_a?(ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper)
        job_class = pobj.job_data["job_class"].constantize
        tracer = pobj.job_data["arguments"].join(" || ") rescue "TRACER_FAILED: #{pobj.inspect}"
        pobj = job_class.deserialize(pobj.job_data)
        raise "Must implement signature for duplicate checking: #{pobj} - #{tracer}" unless pobj.respond_to?(:signature)
      end

      if pobj.respond_to?(:signature)

        if pobj.method(:signature).arity > 0
          sig = pobj.signature(pobj.method_name, pobj.args)
        else
          sig = pobj.signature
        end

      elsif pobj.object.respond_to?(:id) and pobj.object.id.present?
        sig = "#{pobj.object.class}"
        sig += ":#{pobj.object.id}" 
      else
        sig = "#{pobj.object}"
      end
      
      if pobj.respond_to?(:method_name)
        sig += "##{pobj.method_name}" unless sig.match("##{pobj.method_name}")
      end
      
      return sig
    end    

    def prevent_duplicate
      if DuplicateChecker.duplicate?(self)
        handler = YAML.load(self.handler)
        args = handler.args rescue []
        args = args.map{|a| a.kind_of?(Class) ? a.to_s : a}
        Rails.logger.warn "Found duplicate job(#{self.signature})[#{args}], ignoring..."
        errors.add(:base, "This is a duplicate") 
      end
    end
  end

  class DuplicateChecker
    attr_reader :job

    def self.duplicate?(job)
      new(job).duplicate?
    end

    def initialize(job)
      @job = job
    end

    def duplicate?
      # possible_dupes = Delayed::Job.where(signature: job.signature, failed_at: nil)
      # possible_dupes = possible_dupes.where.not(id: job.id) if job.id.present?
      # result = possible_dupes.any?{|possible_dupe| args_match?(possible_dupe, job)}
      # result

      possible_dupes = Delayed::Job.where(signature: job.signature, failed_at: nil, args: job.args)
      possible_dupes = possible_dupes.where.not(id: job.id) if job.id.present?
      return possible_dupes.exists?
    end

    private

    def args_match?(job1, job2)
      # TODO: make this logic robust
      handler1 = YAML.load(job1.handler)
      handler2 = YAML.load(job2.handler)
      handler1.args == handler2.args
    end

  end
end
