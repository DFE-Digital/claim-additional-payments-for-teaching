module Journeys
  extend self

  def self.table_name_prefix
    "journeys_"
  end

  JOURNEYS = [
    TargetedRetentionIncentivePayments,
    TeacherStudentLoanReimbursement,
    GetATeacherRelocationPayment,
    FurtherEducationPayments,
    EarlyYearsPayment::Provider::Start,
    EarlyYearsPayment::Provider::Authenticated,
    EarlyYearsPayment::Provider::AlternativeIdv,
    EarlyYearsPayment::Practitioner
  ].freeze

  def all
    JOURNEYS
  end

  def all_routing_names
    all.map(&:routing_name)
  end

  def legacy_routing_names
    ["additional-payments"]
  end

  def for_routing_name(routing_name)
    all.find { |journey| routing_name == journey.routing_name }
  end

  def for_policy(policy)
    all.find { |journey| journey.policies.include?(policy) }
  end
end
