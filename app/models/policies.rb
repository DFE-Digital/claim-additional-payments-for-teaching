# Module providing access to all the currently active policies for the service.
module Policies
  POLICIES = [
    StudentLoans,
  ].freeze

  def self.all
    POLICIES
  end
end
