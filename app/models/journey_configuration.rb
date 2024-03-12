# Journey-specific configuration, managed through the service operator's admin
# interface.
#
# Things that are currently configurable:
#
# * open_for_submissions: defines whether the journey is currently accepting
#   claims or not
# * availability_message: an optional message that is shown to users when the
#   journey is closed for submissions
# * current_academic_year: the academic year the service is currently accepting
#   claims for.
class JourneyConfiguration < ApplicationRecord
  ACADEMIC_YEAR_REGEXP = /\A20\d{2}\/20\d{2}\z/

  SERVICES = [
    {
      routing_name: "student-loans",
      slug_sequence: Policies::StudentLoans::SlugSequence,
      policies: [Policies::StudentLoans],
      view_path: "student_loans",
      i18n_namespace: "student_loans"
    },
    {
      routing_name: "additional-payments",
      slug_sequence: Policies::EarlyCareerPayments::SlugSequence,
      policies: [Policies::EarlyCareerPayments, LevellingUpPremiumPayments],
      view_path: "additional_payments",
      i18n_namespace: "additional_payments"
    }
  ].freeze

  # Use AcademicYear as custom ActiveRecord attribute type
  attribute :current_academic_year, AcademicYear::Type.new

  validates :current_academic_year_before_type_cast, format: {with: ACADEMIC_YEAR_REGEXP}
  validate :policy_types_must_not_be_configured_already, on: :create

  def self.for(policy)
    where("? = ANY (policy_types)", policy.to_s).first
  end

  def self.service_for_routing_name(routing_name)
    SERVICES.detect { |j| j[:routing_name] == routing_name } || {}
  end

  def self.for_routing_name(routing_name)
    policy = service_for_routing_name(routing_name)[:policies]&.first
    self.for(policy)
  end

  def self.policy_for_routing_name(routing_name)
    service_for_routing_name(routing_name)[:policies]&.first
  end

  def self.i18n_namespace_for_routing_name(routing_name)
    service_for_routing_name(routing_name)[:i18n_namespace]
  end

  def self.policies_for_routing_name(routing_name)
    service_for_routing_name(routing_name)[:policies]
  end

  def self.view_path(routing_name)
    service_for_routing_name(routing_name)[:view_path]
  end

  def self.all_routing_names
    SERVICES.map { |j| j[:routing_name] }
  end

  def self.routing_name_for_policy(policy)
    SERVICES.detect { |j| policy.in? j[:policies] }[:routing_name]
  end

  def self.start_page_url(routing_name)
    service_for_routing_name(routing_name)[:slug_sequence].start_page_url
  end

  def policies
    policy_types.map(&Policies.method(:constantize))
  end

  def routing_name
    SERVICES.detect { |j| policies.first.in? j[:policies] }[:routing_name]
  end

  def slugs
    SERVICES.detect { |j| policies.first.in? j[:policies] }[:slug_sequence]::SLUGS
  end

  def additional_payments?
    policies.include?(Policies::EarlyCareerPayments) || policies.include?(LevellingUpPremiumPayments)
  end

  private

  def policy_types_must_not_be_configured_already
    unless policy_types.map { |policy| self.class.for(policy) }.compact.empty?
      errors.add(:policy_types, "is already configured")
    end
  end
end
