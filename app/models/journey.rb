# Policies should not control the front-end journey as one journey can be an application
# for more than one policy
class Journey
  # routing_name - the path used e.g. /student-loans/claim
  #   this ideally should live somewhere else but keeping it here to start the combined journey work
  # slugs - the slug sequence used for this journey
  # policies - the policies this journey covers, a claim for each policy will be created at the beginning
  ALL = [
    {
      routing_name: "student-loans",
      slugs: StudentLoans::SlugSequence::SLUGS,
      policies: [StudentLoans]
    },
    {
      routing_name: "maths-and-physics",
      slugs: MathsAndPhysics::SlugSequence::SLUGS,
      policies: [MathsAndPhysics]
    },
    {
      routing_name: "early-career-payments",
      slugs: EarlyCareerPayments::SlugSequence::SLUGS,
      policies: [EarlyCareerPayments, LevellingUpPayments],
      # view_path - folder where view templates are, unless folder is the same as routing-name
      view_path: "early_career_payments"
    }
  ].freeze

  def self.all_journey_routing_names
    ALL.map { |j| j[:routing_name] }
  end

  # This is prep work for combined policy journey, mimick one policy per journey for now
  def self.policy_for_routing_name(routing_name)
    ALL.detect { |j| j[:routing_name] == routing_name }[:policies]&.first
  end

  def self.routing_name_for_policy(policy)
    ALL.detect { |j| policy.in? j[:policies] }[:routing_name]
  end

  def self.policies_for_routing_name(routing_name)
    ALL.detect { |j| j[:routing_name] == routing_name }[:policies]
  end

  def self.policy_configuration_for(routing_name)
    policy = policy_for_routing_name(routing_name)
    PolicyConfiguration.for(policy)
  end

  def self.view_path(routing_name)
    ALL.detect { |j| j[:routing_name] == routing_name }[:view_path]
  end

  def self.view_paths
    ALL.map { |j| j[:view_path] }.compact
  end
end
