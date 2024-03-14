# SubmitForm
class SubmitForm
  def self.call(...)
    service = new(...)
    return service unless service.valid?

    service.submit_form!
    service
  end

  def initialize(form, ip_address)
    @form = form
    @ip_address = ip_address
    @success = false
  end
  attr_reader :form, :ip_address, :claim, :eligibility

  delegate :errors, to: :form

  def valid?
    form.validate_completeness
    form.validate_eligibility
    form.errors.blank?
  end

  def success?
    @success
  end

  def submit_form!
    create_claim_records
    send_applicant_email
    @success = true
  end

  private

  def add_dummy_values_to_claim
    claim.teacher_reference_number = "1234567"
    claim.national_insurance_number = "AA123456C"
    claim.has_student_loan = true
    claim.student_loan_plan = "plan_1"
    claim.has_masters_doctoral_loan = false
    claim.postgraduate_masters_loan = false
    claim.postgraduate_doctoral_loan = false
    claim.bank_or_building_society = Claim.bank_or_building_societies[:personal_bank_account]
    claim.banking_name = "Jane Doe"
    claim.bank_sort_code = "20-00-00"
    claim.bank_account_number = "12345678"
  end

  def create_claim_records
    ActiveRecord::Base.transaction do
      # Eligibility must exist before the claim can be created.
      create_eligibility
      create_claim
      add_dummy_values_to_claim
      claim.submit!
      eligibility.submit!
      # delete_form
    end
  end

  def create_claim
    @claim = Claim.create!(
      first_name: form.given_name,
      middle_name: form.middle_name,
      surname: form.family_name,
      address_line_1: form.address_line_1,
      address_line_2: form.address_line_2,
      address_line_3: form.city,
      # address_line_4: nil,
      postcode: form.postcode,
      date_of_birth: form.date_of_birth,
      payroll_gender: Claim.payroll_genders[form.sex],
      email_address: form.email_address,
      email_verified: true,
      provide_mobile_number: true,
      mobile_number: form.phone_number,
      eligibility: @eligibility,
      academic_year: "2023/2024", # TODO: Fix this!
      has_student_loan: form.student_loan
    )
  end

  def create_eligibility
    @eligibility = Irp::Eligibility.create!(
      {
        one_year: form.one_year,
        state_funded_secondary_school: form.state_funded_secondary_school,
        date_of_entry: form.date_of_entry,
        start_date: form.start_date,
        application_route: form.application_route,
        ip_address: ip_address,
        nationality: form.nationality,
        passport_number: form.passport_number,
        school_headteacher_name: form.school_headteacher_name,
        school_name: form.school_name,
        school_address_line_1: form.school_address_line_1,
        school_address_line_2: form.school_address_line_2,
        school_city: form.school_city,
        school_postcode: form.school_postcode,
        subject: SubjectStep.new(form).answer.formatted_value,
        visa_type: form.visa_type
      }
    )
  end

  # def create_application
  #   @application = Application.create!(
  #     applicant: @applicant,
  #     application_date: Date.current.to_s,
  #     application_route: form.application_route,
  #     application_progress: ApplicationProgress.new,
  #     date_of_entry: form.date_of_entry,
  #     start_date: form.start_date,
  #     subject: SubjectStep.new(form).answer.formatted_value,
  #     visa_type: form.visa_type,
  #   )
  # end

  def delete_form
    form.destroy!
    Event.publish(:deleted, form)
  end

  def send_applicant_email
    # GovukNotifyMailer
    #   .with(
    #     email: @applicant.email_address,
    #     urn: application.urn,
    #   )
    #   .application_submission
    #   .deliver_later
  end
end
