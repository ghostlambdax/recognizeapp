class ExternalActivity < ApplicationRecord
  belongs_to :actor, foreign_key: :actor_id, class_name: "User", optional: true
  belongs_to :receiver, foreign_key: :receiver_id, class_name: "User", optional: true
  belongs_to :company, optional: true

  validates :source, inclusion: { in: %w(yammer) }
  validates :source_id, presence: true
  validates :name, inclusion: { in: %w(post comment like) }
  validates :company_id, presence: true
  validates :actor_id, presence: true

  serialize :source_metadata, Hash

  POST = "post"
  COMMENT = "comment"
  LIKE = "like"

  def self.group_like_stats(company:, groups: {}, start_date: nil, end_date: nil)
    like_stats = ExternalActivity.where(company_id: company.id, name: "like", target_name: "post")
                  .where(group_id: groups.keys)
                  .where("actor_id <> receiver_id")

    if start_date && end_date
      like_stats.merge!(where("DATE(created_at) between DATE(?) and DATE(?)", start_date, end_date))
    end

    like_stats = like_stats.group(:group_id).count
    like_stats = like_stats.map do |group_id, like_count|
      RecognizeOpenStruct.new(rank: nil, group_id: group_id, group_name: groups[group_id], like_count: like_count)
    end

    groupings = like_stats.group_by(&:like_count)
    groupings.keys.sort.reverse.each.with_index do |key, index|
      groupings[key].each { |group| group.rank = index+1 }
    end

    like_stats.sort_by(&:rank)
  end

  def self.user_like_stats(company:, start_date: nil, end_date: nil)
    like_stats = company.users.includes(:likes, :avatar).map do |user|
      likes = if start_date && end_date
                user.likes.between(start_date: start_date, end_date: end_date)
              else
                user.likes
              end
      RecognizeOpenStruct.new(rank: nil, user: user, like_count: likes.count)
    end

    like_stats.reject!{|stat| stat.like_count == 0 }

    groupings = like_stats.group_by(&:like_count)
    groupings.keys.sort.reverse.each.with_index do |key, index|
      groupings[key].each { |group| group.rank = index+1 }
    end

    like_stats.sort_by(&:rank)
  end

  def self.new_from_yammer_message(message)
    self.new.tap do |activity|
      activity.name = message.is_a?(ExternalActivities::Yammer::Post) ? POST : COMMENT
      activity.actor_id = message.sender.try(:id)
      activity.receiver_id = message.receiver.try(:id)
      activity.target_id = message.target_id
      activity.target_name = message.target_name
      activity.group_id = message.group_id
      activity.company_id = message.company_id
      activity.created_at = message.created_at
      activity.source = "yammer"
      activity.source_id = message.id.to_s
      activity.source_metadata = message.metadata
      activity.synced_at = Time.now
    end
  end

  def self.create_from_yammer_message!(message)
    activity = new_from_yammer_message(message)
    activity.save! && activity
  end

  def self.new_from_yammer_like(like)
    self.new.tap do |activity|
      activity.source = "yammer"
      activity.source_id = like.id.to_s
      activity.company_id = like.company_id
      # only if we want to make like appear to have occurred
      # when post/comment occurred
      # activity.created_at = like.metadata["msg_created_at"]
      activity.group_id = like.group_id
      activity.target_id = like.target_id
      activity.target_name = like.target_name
      activity.source_metadata = like.metadata
      activity.actor_id = like.sender.try(:id)
      activity.receiver_id = like.receiver.try(:id)
      activity.name = LIKE
      activity.synced_at = Time.now
    end
  end

  def self.create_from_yammer_like!(like)
    activity = new_from_yammer_like(like)
    activity.save! && activity
  end

  def self.save_new_activities(activities)
    activities.each do |a|
      query = {
          name: a.name,
          actor_id: a.actor_id,
          receiver_id: a.receiver_id,
          group_id: a.group_id,
          company_id: a.company_id,
          source: a.source,
          source_id: a.source_id,
      }

      a.save! unless self.exists?(query)
    end
  end

end
