class EmailLog < ApplicationRecord
  belongs_to :user, foreign_key: "email"
  validates :from, :to, :subject, :body, :date, presence: true
end