module Journeys
  extend self

  JOURNEYS = [
    AdditionalPaymentsForTeaching,
    TeacherStudentLoanReimbursement
  ].freeze

  def all
    JOURNEYS
  end

  def all_routing_names
    all.map {|journey| journey::ROUTING_NAME }
  end

  def for_routing_name(routing_name)
    all.find {|journey| journey::ROUTING_NAME == routing_name }
  end

  def for_policy(policy)
    all.find {|journey| journey::POLICIES.include?(policy) }
  end
end
