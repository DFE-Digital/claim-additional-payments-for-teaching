class Note < ApplicationRecord
  belongs_to :claim
  belongs_to :created_by, class_name: "DfeSignIn::User", optional: true

  validates :body, presence: {message: "Enter a note"}, on: :create_note
  validates :body, presence: {message: "Enter why you are putting the claim on hold"}, on: :hold_claim

  scope :automated, -> { where(created_by_id: nil) }
  scope :by_label, ->(label) { order(created_at: :desc).where(label: label) }

  def task_note?
    Task::NAMES.include?(label)
  end
end
