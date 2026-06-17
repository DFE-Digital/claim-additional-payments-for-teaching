module Admin
  class ComponentsController < BaseAdminController
    before_action :ensure_service_operator

    PREVIEW_SESSION_LENGTH_IN_SECONDS = 2.hours.to_i

    DEFAULT_PREPOPULATED_ANSWERS = {
      first_name: "Alex",
      middle_name: "Jordan",
      surname: "Taylor",
      date_of_birth: Date.new(1990, 1, 1),
      national_insurance_number: "QQ123456C",
      teacher_reference_number: "1234567",
      payroll_gender: "male",
      email_address: "alex.taylor@example.org",
      email_verified: true,
      provide_mobile_number: false,
      mobile_verified: true,
      details_check: false,
      logged_in_with_tid: false,
      logged_in_with_onelogin: false,
      identity_confirmed_with_onelogin: false,
      have_one_login_account: "false",
      address_line_1: "1 High Street",
      address_line_2: "Exampleton",
      address_line_3: "Example City",
      postcode: "SW1A 1AA",
      postcode_in_uk: true,
      skip_postcode_search: false,
      bank_or_building_society: "bank",
      bank_sort_code: "123456",
      bank_account_number: "12345678",
      banking_name: "Alex Taylor",
      hmrc_bank_validation_succeeded: true,
      previously_claimed: false,
      information_provided_completed: true
    }.freeze

    def index
      redirect_to journey_components_path
    end

    def open
      journey = Journeys.for_routing_name(params[:journey])
      slug = params[:slug].to_s

      if journey.blank? || !journey.slug_sequence::SLUGS.include?(slug)
        return redirect_to(journey_components_path, alert: "Journey or component not found")
      end

      create_prepopulated_preview_session!(journey, slug)

      session[:admin_component_preview] = {
        journey: journey.routing_name,
        expires_at: Time.zone.now.to_i + PREVIEW_SESSION_LENGTH_IN_SECONDS
      }

      redirect_to claim_path(journey.routing_name, slug, skip_landing_page: true)
    end

    private

    def create_prepopulated_preview_session!(journey, slug)
      ensure_preview_journey_configuration!(journey)

      session_key = :"#{journey.routing_name}_journeys_session_id"
      session.delete(session_key)

      journey_session = journey::Session.create!(
        journey: journey.routing_name,
        answers: {
          academic_year: current_academic_year_for(journey),
          **default_answers_for(journey, slug)
        },
        steps: journey.slug_sequence::SLUGS
      )

      session[session_key] = journey_session.id
      session[:current_journey_routing_name] = journey.routing_name
    end

    def default_answers_for(journey, slug)
      sample_school = School.open.first
      default_answers = DEFAULT_PREPOPULATED_ANSWERS.deep_dup

      if sample_school
        default_answers[:current_school_id] = sample_school.id
        default_answers[:possible_school_id] = sample_school.id
        default_answers[:provision_search] = sample_school.name
      end

      allowed_attributes = journey::SessionAnswers.attribute_names

      default_answers
        .merge(ineligible_preview_answers_for(journey, slug))
        .slice(*allowed_attributes.map(&:to_sym))
    end

    def current_academic_year_for(journey)
      Journeys::Configuration.unscoped.find_by(routing_name: journey.routing_name)&.current_academic_year || AcademicYear.current
    end

    def ensure_preview_journey_configuration!(journey)
      Journeys::Configuration.unscoped.find_or_create_by!(routing_name: journey.routing_name) do |configuration|
        configuration.current_academic_year = AcademicYear.current
        configuration.open_for_submissions = true
      end
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
