module Journeys
  extend self

  def self.table_name_prefix
    "journeys_"
  end

  JOURNEYS = [
    AdditionalPaymentsForTeaching,
    TeacherStudentLoanReimbursement,
    GetATeacherRelocationPayment,
    FurtherEducationPayments,
    FurtherEducationPayments::Provider,
    EarlyYearsPayment::Provider::Start,
    EarlyYearsPayment::Provider::Authenticated,
    EarlyYearsPayment::Practitioner
  ].freeze

  def all
    JOURNEYS
  end

  def all_routing_names
    all.map(&:routing_name)
  end

  def for_routing_name(routing_name)
    all.find { |journey| routing_name == journey::ROUTING_NAME }
  end

  def for_policy(policy)
    all.find { |journey| journey::POLICIES.include?(policy) }
  end
end
