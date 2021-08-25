class Comment < ApplicationRecord

  acts_as_paranoid
  belongs_to :company
  belongs_to :commentable, polymorphic: true
  belongs_to :recognition, -> { where( comments: { commentable_type: 'Recognition' } ).includes( :comments ) }, foreign_key: 'commentable_id', optional: true
  belongs_to :commenter, class_name: "User"

  validates :company_id, :commenter_id, :commentable_id, :commentable_type, :content, presence: true

  before_validation { self.company_id = self.commenter&.company_id }
  after_create :send_notifications

  scope :visible, -> { where(is_hidden: false) }

  def commenter
    User.unscoped { super }
  end

  def hide!
    self.update_column(:is_hidden, true)
  end

  def unhide!
    self.update_column(:is_hidden, false)
  end

  def uniq_dom_id
    "#{commentable_type.downcase}-#{commentable_id}-comment-#{id}"
  end

  protected

  def send_notifications
    commentable = self.commentable
    notification_recipients = commentable.flattened_recipients + [commentable.sender] + commentable.comments.collect{|c| c.commenter}
    notification_recipients = notification_recipients.reject(&:system_user?) # Anniversary recognition or ambassador recognition.
    notification_recipients = notification_recipients.uniq
    notification_recipients.each do |r|
      next if r == self.commenter
      UserNotifier.delay(queue: 'priority').new_comment(r, self)
    end
  end

end
