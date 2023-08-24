class DqtService
  include Dqt::Matchers::EarlyCareerPayments
  include Dqt::Matchers::LevellingUpPremiumPayments
  include Dqt::Matchers::General

  def initialize(current_claim)
    @current_claim = current_claim
  end

  def request
    dqt_api_url = build_dqt_api_url
    http = Net::HTTP.new(dqt_api_url.host, dqt_api_url.port)
    http.use_ssl = (dqt_api_url.scheme == "https")

    request = Net::HTTP::Get.new(dqt_api_url)
    request["Authorization"] = "Bearer #{ENV["DQT_API_KEY"]}"

    response = http.request(request)

    if response.code.eql?("200")
      data = JSON.parse(response.body)
      set_teacher_data(data)
    end

    response
  end

  private

  attr_reader :current_claim, :dqt_data

  def set_teacher_data(response)
    @dqt_data = response["initial_teacher_training"]

    set_qualification
    set_itt_academic_year

    case current_claim.eligibility_type
    when "EarlyCareerPayments::Eligibility"
      set_ecp_eligible_itt_subject
    when "LevellingUpPremiumPayments::Eligibility"
      set_lup_eligible_itt_subject
    end
  end

  def set_qualification
    current_claim.eligibility.qualification = if check_qualification(:postgraduate_itt)
      "postgraduate_itt"
    elsif check_qualification(:undergraduate_itt)
      "undergraduate_itt"
    elsif check_qualification(:assessment_only)
      "assessment_only"
    elsif check_qualification(:overseas_recognition)
      "overseas_recognition"
    end
  end

  def set_ecp_eligible_itt_subject
    current_claim.eligibility.eligible_itt_subject = if check_ecp_eligible_itt_subject(:mathematics)
      "mathematics"
    elsif check_ecp_eligible_itt_subject(:chemistry)
      "chemistry"
    elsif check_ecp_eligible_itt_subject(:foreign_languages)
      "foreign_languages"
    elsif check_ecp_eligible_itt_subject(:physics)
      "physics"
    else
      "none_of_the_above"
    end
  end

  def set_lup_eligible_itt_subject
    current_claim.eligibility.eligible_itt_subject = if check_lup_eligible_itt_subject(:mathematics)
      "mathematics"
    elsif check_lup_eligible_itt_subject(:chemistry)
      "chemistry"
    elsif check_lup_eligible_itt_subject(:computing)
      "computing"
    elsif check_lup_eligible_itt_subject(:physics)
      "physics"
    else
      "none_of_the_above"
    end
  end

  def check_qualification(degree)
    QUALIFICATION_MATCHING_TYPE[degree].include?(dqt_data["qualification"])
  end

  def check_ecp_eligible_itt_subject(itt_subject)
    Dqt::Matchers::EarlyCareerPayments::ELIGIBLE_ITT_SUBJECTS[itt_subject].include?(dqt_data["subject1"])
  end

  def check_lup_eligible_itt_subject(itt_subject)
    Dqt::Matchers::LevellingUpPremiumPayments::ELIGIBLE_ITT_SUBJECTS[itt_subject].include?(dqt_data["subject1"])
  end

  def set_itt_academic_year
    start_date = Time.parse(dqt_data["programme_start_date"])
    current_claim.eligibility.update(itt_academic_year: AcademicYear.new(start_date.year))
  end

  def build_dqt_api_url
    # URI.parse("#{ENV["DQT_BASE_URL"]}/v1/teachers/1886094?birthdate=1993-07-25")
    URI.parse("#{ENV["DQT_BASE_URL"]}/v1/teachers/#{current_claim.teacher_reference_number}?birthdate=#{current_claim.date_of_birth}")
  end
end
