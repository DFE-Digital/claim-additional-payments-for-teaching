# frozen_string_literal: true

# Checks are performed against a claim by service operators
# Only one check of a particular type can be carried out per claim
# These checks were designed to make the process of checking a
# claim more granular

# It records who completed the check and the date/time the action
# was carried out

class Check < ApplicationRecord
  belongs_to :claim
  belongs_to :created_by, class_name: "DfeSignIn::User"

  validates :name, uniqueness: {scope: :claim_id}
end
