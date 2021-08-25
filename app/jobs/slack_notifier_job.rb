# frozen_string_literal: true

class SlackNotifierJob < ApplicationJob
  attr_reader :opts

  def perform(opts)
    @opts = opts
    say!
  end

  def named_job_arguments(job_arguments, hash)
    opts = job_arguments[0]
    hash[:text] = opts[:text]
    return hash
  end

  def signature
    "SlackNotifierJob-#{@text}-#{self.job_id}"
  end

  private

  def say!
    begin
      ::Recognizebot.say(opts)
    rescue => e
      ExceptionNotifier.notify_exception(e, {data: opts})
    end
  end
end
