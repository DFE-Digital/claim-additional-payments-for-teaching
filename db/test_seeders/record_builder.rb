class RecordBuilder
  include Seeder

  attr_reader :records

  def initialize(quantity:)
    @quantity = quantity
    @records = []
    @logger = Logger.new($stdout)
    build_records
  end

  Struct.new(
    "DataRecord",
    "Payroll Gender",
    "Claimant Name",
    "DOB",
    "Trn",
    "NINumber",
    "Post / Undergraduate / AO / Overseas",
    "Subject Code",
    "ITT Cohort Year"
  )

  private

  attr_reader :quantity, :logger

  def build_records
    logger.info "RecordBuilder: building #{quantity} records ..."

    quantity.to_i.times do |n|
      records << build_record
      print "."
    end
    puts "\n"
    logger.info LINE
  end

  # As payroll testing is for 2021/2022 AY,
  # have used 2018-2019 and Mathematics
  # as this was the valid cohort for ECP
  def build_record
    gender ||= payroll_gender
    Struct::DataRecord.new(
      (gender == :male) ? "M" : "F",
      [first_name(gender), surname].join(" "),
      dob,
      rand(1000000..9999999).to_s,
      nino,
      qualification,
      subject,
      "2018-2019"
    )
  end

  # As payroll testing is for 2021/2022 AY,
  # have used :mathematics as the key
  # as this was the valid cohort for ECP
  def subject
    [
      Policies::EarlyCareerPayments::DqtRecord::ELIGIBLE_JAC_CODES[:mathematics],
      Policies::EarlyCareerPayments::DqtRecord::ELIGIBLE_HECOS_CODES[:mathematics]
    ].flatten.sample
  end

  def qualification
    ["Postgraduate", "Undergraduate", "Assessment Only", "Overseas Recognition"].sample
  end

  def dob
    rand(Date.new(1980, 1, 1)..Date.new(2000, 12, 31)).strftime("%d/%m/%Y")
  end

  def payroll_gender
    gender = %i[male female dont_know].sample
    (gender == :dont_know) ? %i[male female].sample : gender
  end

  def first_name(gender)
    Faker::Name.send(:"#{gender}_first_name")
  end

  def surname
    double_barrelled_surname = [7, 9].include? Random.rand(10)

    last_names = []
    if double_barrelled_surname == true
      2.times do
        last_names << Faker::Name.last_name
      end
      last_names.join("-")
    else
      Faker::Name.last_name
    end
  end

  def nino
    loop {
      ref = [nino_prefix, nino_numbers, nino_suffix].join
      break ref if ref.size == 9
    }
  end

  def nino_prefix
    nino_prefix_first_letter = Array.new(1) { [*"A".."Z"].reject { |char| %w[D F I Q U V].include?(char) }.sample }
    nino_prefix_second_letter = Array.new(1) { [*"A".."N", *"P".."Z"].reject { |char| %w[D F I Q U V].include?(char) }.sample }
    [[nino_prefix_first_letter, nino_prefix_second_letter].join].reject { |prefix| %w[BG GB KN NK NT TN ZZ].include?(prefix) }
  end

  def nino_suffix
    Array.new(1) { [*"A".."D"].sample }
  end

  def nino_numbers
    Random.rand(100000..999999)
  end
end
