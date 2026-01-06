class Event < ApplicationRecord
  belongs_to :claim
  belongs_to :actor, class_name: "DfeSignIn::User", optional: true
  belongs_to :entity, polymorphic: true, optional: true

  validates :name, presence: true
end
