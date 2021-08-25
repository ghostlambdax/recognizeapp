module Tskz
  class TaskSubmissionNotifier < ApplicationMailer
    include MailHelper
    include DateTimeHelper

    helper :mail
    helper :date_time

    layout "user_mailer"

    # called when task_submission is created
    def notify_manager(task_submission)
      @submitter = task_submission.submitter
      @manager = @submitter.manager
      I18n.with_locale(@manager.locale) do
        mail(to: @manager.email, subject: I18n.t("tskz.notifier.requesting_approval_of_tasks", name: @submitter.full_name), track_opens: true)
      end
    end

    # called when task_submission is created (if no relevant manager)
    def notify_company_admin(admin, task_submission)
      @submitter = task_submission.submitter

      I18n.with_locale(admin.locale) do
        mail(to: admin.email, subject: I18n.t("tskz.notifier.requesting_approval_of_tasks", name: @submitter.full_name), track_opens: true)
      end
    end

    # called on resolution of a task submission
    def notify_submitter(task_submission)
      @submitter = task_submission.submitter
      @resolver = task_submission.approver
      @message = task_submission.approval_comment
      @completed_tasks = task_submission.completed_tasks

      action = if @completed_tasks.all?(&:approved?)
                 :approved
               elsif @completed_tasks.all?(&:denied?)
                 :denied
               else
                 # task submission has some completed tasks approved and some denied
                 :both_approved_and_denied
               end

      key = "tskz.notifier.#{action}_your_tasks"
      subject = if action == :both_approved_and_denied
                   approved_task_count = @completed_tasks.select(&:approved?).size
                   I18n.t(key, resolver: @resolver.full_name, approved_task_count: approved_task_count, total_task_count: @completed_tasks.length)
                 else
                   I18n.t(key, resolver: @resolver.full_name)
                 end
      I18n.with_locale(@submitter.locale) do
        mail(to: @submitter.email, subject: subject, track_opens: true)
      end
    end
  end
end
