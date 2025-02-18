module TestSeeders
  class ClaimsImporter
    CLAIM_COLUMNS = [
      :first_name,
      :surname,
      :payroll_gender,
      :date_of_birth,
      :teacher_reference_number,
      :national_insurance_number,
      :email_address,
      :email_verified,
      :academic_year,
      :eligibility_id,
      :eligibility_type,
      :banking_name,
      :bank_or_building_society,
      :bank_sort_code,
      :bank_account_number,
      :building_society_roll_number,
      :provide_mobile_number,
      :address_line_1,
      :address_line_2,
      :address_line_3,
      :address_line_4,
      :postcode,
      :has_student_loan,
      :student_loan_plan,
      :created_at,
      :updated_at
    ].freeze

    def initialize(records, eligibilities)
      @records = records
      @logger = Logger.new($stdout)
      @eligibilities = eligibilities
    end

    def run
      logger.info "Seeding #{records.size} Claims"
      insert_claims
    end

    private

    attr_reader :records, :logger, :eligibilities, :first_name, :surname, :initials_first_name

    def insert_claims
      eligibility_type ||= eligibilities.first.class.name
      claim_academic_year ||= eligibilities.first.policy.current_academic_year.to_s

      Claim.copy_from_client CLAIM_COLUMNS do |copy|
        records.each do |data|
          time = Time.now.getutc
          eligibility = eligibilities.shift

          personal_details ||= build_personal_details(data)
          address ||= build_address
          student_loans ||= build_student_loans
          bank_details ||= build_bank_details(data)

          copy << [
            personal_details[:first_name],
            personal_details[:surname],
            personal_details[:payroll_gender],
            personal_details[:date_of_birth],
            personal_details[:teacher_reference_number],
            personal_details[:national_insurance_number],
            personal_details[:email_address],
            personal_details[:email_verified],
            claim_academic_year,
            eligibility.id,
            eligibility_type,
            bank_details[:banking_name],
            bank_details[:personal_bank_account],
            bank_details[:sort_code],
            bank_details[:bank_account_number],
            bank_details[:building_society_roll_number],
            false,
            address[:address_line_1],
            address[:address_line_2],
            address[:address_line_3],
            nil,
            address[:postcode],
            student_loans[:has_student_loan],
            student_loans[:student_loan_plan],
            time,
            time
          ]
        end
      end
    end

    def build_personal_details(data)
      @first_name, @surname = data["Claimant Name"].split
      @initials_first_name = first_name.partition("-").map(&:chars).map(&:first).join.downcase

      {
        first_name: first_name,
        surname: surname,
        payroll_gender: payroll_gender(data),
        date_of_birth: Date.parse(data["DOB"]),
        teacher_reference_number: data["Trn"],
        national_insurance_number: data["NINumber"],
        email_address: email_address,
        email_verified: true
      }
    end

    def email_address
      [initials_first_name, ".", surname.downcase, "@example.com"].join
    end

    def build_address
      address_line_1 = if [4, 9].include? Random.rand(10)
        building_suffix = %w[Cottage Tower House Block].sample
        [Faker::Address.secondary_address, [Faker::Address.county, building_suffix].join(" ")].join(", ")
      else
        Faker::Address.building_number
      end
      {
        address_line_1: address_line_1,
        address_line_2: Faker::Address.street_name,
        address_line_3: Faker::Address.city,
        postcode: Faker::Address.postcode
      }
    end

    def build_student_loans
      student_loan_details = {
        has_student_loan: nil,
        student_loan_plan: Claim::NO_STUDENT_LOAN
      }
      if rand(100) < 85
        student_loan_details[:has_student_loan] = true
        student_loan_details[:student_loan_plan] = StudentLoan::PLAN.sample
      else
        student_loan_details[:has_student_loan] = false
      end

      student_loan_details
    end

    def payroll_gender(data)
      case data["Payroll Gender"]
      when "F"
        1
      when "M"
        2
      else
        0
      end
    end

    def build_bank_details(data)
      banking_details = {
        banking_name: [with_title? ? title(data) : nil, first_name, surname].reject(&:blank?).join(" "),
        personal_bank_account: bank_or_building_society,
        sort_code: rand(100000..999999).to_s,
        bank_account_number: rand(10000000..99999999).to_s,
        building_society_roll_number: nil
      }
      banking_details[:building_society_roll_number] = build_building_society_roll_number(banking_details[:personal_bank_account] == 1)
      banking_details
    end

    def title(data)
      case data["Payroll Gender"]
      when "F"
        %w[Miss Ms Mrs Dr Prof. Lady].sample
      when "M"
        %w[Master Mr Dr Prof. Sir].sample
      else
        %w[Dr Prof.].sample
      end
    end

    def with_title?
      [2, 6].include? Random.rand(10)
    end

    def bank_or_building_society
      if [2, 6].include? Random.rand(10)
        1
      else
        0
      end
    end

    def build_building_society_roll_number(required)
      return unless required
      o = [("a".."z"), ("A".."Z"), 0..9].map(&:to_a).flatten
      o.push(" ")
      o.push("/")
      o.push("-")
      (0...18).map { o[rand(o.length)] }.join
    end
  end
end
