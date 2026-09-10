class JourneyComponentPreviewUrlBuilder
  PREVIEW_SESSION_LENGTH_IN_SECONDS = 2.hours.to_i

  class << self
    def call(journey:, slug:, session: nil, controller: nil)
      if session.present? && controller.present?
        call!(journey:, slug:, session:, controller:)
      end

      Rails.application.routes.url_helpers.claim_path(journey.routing_name, slug, skip_landing_page: true)
    end

    def call!(journey:, slug:, session:, controller:)
      create_prepopulated_preview_session!(journey:, slug:, session:, controller:)

      session[:admin_component_preview] = {
        journey: journey.routing_name,
        expires_at: Time.zone.now.to_i + PREVIEW_SESSION_LENGTH_IN_SECONDS
      }

      Rails.application.routes.url_helpers.claim_path(journey.routing_name, slug, skip_landing_page: true)
    end

    private

    def create_prepopulated_preview_session!(journey:, slug:, session:, controller:)
      session_key = :"#{journey.routing_name}_journeys_session_id"
      session.delete(session_key)

      journey_session = journey::Session.create!(
        journey: journey.routing_name,
        answers: {
          academic_year: current_academic_year_for(journey),
          **default_answers_for(journey, slug, controller:)
        },
        steps: journey.slug_sequence::SLUGS
      )

      session[session_key] = journey_session.id
      session[:current_journey_routing_name] = journey.routing_name
    end

    def default_answers_for(journey, slug, controller:)
      sample_school = sample_school_for(journey)
      default_answers = Admin::ComponentsController::DEFAULT_PREPOPULATED_ANSWERS.deep_dup

      if sample_school
        default_answers[:current_school_id] = sample_school.id
        default_answers[:possible_school_id] = sample_school.id
        default_answers[:school_id] = sample_school.id
        default_answers[:provision_search] = sample_school.name
      end

      allowed_attributes = journey::SessionAnswers.attribute_names

      default_answers
        .merge(ineligible_preview_answers_for(journey, slug))
        .slice(*allowed_attributes.map(&:to_sym))
    end

    def sample_school_for(journey)
      return School.open.first unless journey == Journeys::FurtherEducationPayments

      School.open.fe_only.find do |school|
        school.eligible_fe_provider(academic_year: current_academic_year_for(journey)).present?
      end || School.open.fe_only.first || School.open.first
    end

    def current_academic_year_for(journey)
      Journeys::Configuration.find_by(routing_name: journey.routing_name)&.current_academic_year || AcademicYear.current
    end

    def ineligible_preview_answers_for(journey, slug)
      return {} unless slug == "ineligible"

      case journey.routing_name
      when Journeys::TeacherStudentLoanReimbursement.routing_name
        {employment_status: "no_school"}
      when Journeys::TargetedRetentionIncentivePayments.routing_name
        {subject_to_formal_performance_action: true}
      when Journeys::FurtherEducationPayments.routing_name
        school = School.closed.first || School.first
        {
          teaching_responsibilities: true,
          school_id: school&.id
        }.compact
      when Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
        {
          teaching_qualification_confirmation: false,
          skip_postcode_search: true
        }
      when Journeys::EarlyYearsPayment::Provider::Start.routing_name
        {email_address: "preview.not-on-whitelist@example.org"}
      when Journeys::EarlyYearsPayment::Provider::Authenticated.routing_name
        {nursery_urn: "none_of_the_above"}
      when Journeys::EarlyYearsPayment::Practitioner.routing_name
        {reference_number_found: false}
      else
        {}
      end
    end
  end
end
