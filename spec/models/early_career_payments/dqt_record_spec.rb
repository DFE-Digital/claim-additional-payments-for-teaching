require "rails_helper"

RSpec.describe EarlyCareerPayments::DqtRecord do
  subject(:dqt_record) do
    described_class.new(
      record,
      claim
    )
  end

  let(:claim) do
    build_stubbed(
      :claim,
      academic_year: claim_academic_year
    )
  end

  let(:record) do
    OpenStruct.new(
      {
        degree_codes: record_degree_codes,
        itt_subjects: record_itt_subjects,
        itt_subject_codes: record_itt_subject_codes,
        itt_start_date: record_itt_date,
        qts_award_date: record_qts_date,
        qualification_name: record_qualification_name
      }
    )
  end

  describe "#eligible?" do
    subject(:eligible?) { dqt_record.eligible? }

    [
      # start of mathematics for 2021
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2017"),
        record_qualification_name: "Degree"
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA (Hons)"
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2017"),
        record_qualification_name: "Degree Equivalent (this will include foreign qualifications)"
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA (Hons) Combined Studies/Education of the Deaf"
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "EEA"
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA/Education (QTS)"
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2017"),
        record_qualification_name: nil
      },
      # end of mathematics for 2021

      # start of mathematics for 2022
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "BEd"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("1/9/2017"),
        record_qualification_name: "Flexible - PGCE"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "BEd (Hons)"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("1/9/2017"),
        record_qualification_name: "Flexible - ProfGCE"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "BSc"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("1/9/2017"),
        record_qualification_name: "Graduate Certificate in Education"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "BSc (Hons)"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("1/9/2017"),
        record_qualification_name: "Graduate Diploma"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BSc (Hons) with Intercalated PGCE"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2020"),
        record_qts_date: Date.parse("1/9/2017"),
        record_qualification_name: "GTP"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BSc/Education (QTS)"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2020"),
        record_qts_date: Date.parse("1/9/2017"),
        record_qualification_name: "Masters, not by research"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "Undergraduate Master of Teaching"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2020"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "Northern Ireland"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2020"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "OTT"
      },
      # end of mathematics for 2022

      # start of physics for 2022
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: ["F300"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: ["F300"],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("31/12/2020"),
        record_qualification_name: "OTT Recognition"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["F300"],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["F300"],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2020"),
        record_qts_date: Date.parse("1/9/2017"),
        record_qualification_name: "Postgraduate Certificate in Education"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: ["100425"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: ["100425"],
        record_itt_date: Date.parse("1/9/2020"),
        record_qts_date: Date.parse("1/9/2017"),
        record_qualification_name: "Postgraduate Certificate in Education (Flexible)"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["100425"],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["100425"],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2020"),
        record_qts_date: Date.parse("1/9/2017"),
        record_qualification_name: "Postgraduate Diploma in Education"
      },
      # end of physics for 2022

      # start of chemistry for 2022
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: ["F100"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: ["F100"],
        record_itt_date: Date.parse("1/9/2020"),
        record_qts_date: Date.parse("1/9/2017"),
        record_qualification_name: "Professional Graduate Certificate in Education"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["F100"],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["F100"],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2020"),
        record_qts_date: Date.parse("1/9/2017"),
        record_qualification_name: "Professional Graduate Diploma in Education"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: ["100417"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: ["100417"],
        record_itt_date: Date.parse("10/05/2020"),
        record_qts_date: Date.parse("07/06/2021"),
        record_qualification_name: "QTS Assessment only"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["100417"],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["100417"],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("17/05/2021"),
        record_qualification_name: "QTS Award only"
      },
      # end of chemistry for 2022

      # start of foreign_languages for 2022
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["foreign languages"],
        record_itt_subject_codes: ["Q100"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["foreign languages"],
        record_itt_subject_codes: ["Q100"],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "Scotland"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["Q100"],
        record_itt_subjects: ["foreign languages"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["Q100"],
        record_itt_subjects: ["foreign languages"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2020"),
        record_qts_date: Date.parse("1/9/2017"),
        record_qualification_name: "Teach First"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["foreign languages"],
        record_itt_subject_codes: ["100321"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["foreign languages"],
        record_itt_subject_codes: ["100321"],
        record_itt_date: Date.parse("1/9/2020"),
        record_qts_date: Date.parse("1/9/2017"),
        record_qualification_name: "Teach First (TNP)"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["100321"],
        record_itt_subjects: ["foreign languages"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["100321"],
        record_itt_subjects: ["foreign languages"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2020"),
        record_qts_date: Date.parse("1/9/2017"),
        record_qualification_name: "Teachers Certificate"
      },
      # end of foreign_languages for 2022

      # start of mathematics for 2023
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2017"),
        record_qualification_name: "Unknown"
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      # end of mathematics for 2023

      # start of physics for 2023
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: ["F300"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["F300"],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: ["100425"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["100425"],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      # end of physics for 2023

      # start of chemistry for 2023
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: ["F100"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["F100"],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: ["100417"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["100417"],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      # end of chemistry for 2023

      # start of foreign_languages for 2023
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["foreign languages"],
        record_itt_subject_codes: ["Q100"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["Q100"],
        record_itt_subjects: ["foreign languages"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["foreign languages"],
        record_itt_subject_codes: ["100321"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["100321"],
        record_itt_subjects: ["foreign languages"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      # end of foreign_languages for 2023

      # start of mathematics for 2024
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      # end of mathematics for 2024

      # start of physics for 2024
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: ["F300"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["F300"],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: ["100425"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["100425"],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      # end of physics for 2024

      # start of chemistry for 2024
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: ["F100"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["F100"],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: ["100417"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["100417"],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      # end of chemistry for 2024

      # start of foreign_languages for 2024
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subjects: ["foreign languages"],
        record_itt_subject_codes: ["Q100"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["Q100"],
        record_itt_subjects: ["foreign languages"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subjects: ["foreign languages"],
        record_itt_subject_codes: ["100321"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["100321"],
        record_itt_subjects: ["foreign languages"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      }
      # end of foreign_languages for 2024
    ].each do |context|
      context "when claim academic year #{context[:claim_academic_year]}" do
        let(:claim_academic_year) { context[:claim_academic_year] }

        context "when record degree codes #{context[:record_degree_codes]}" do
          let(:record_degree_codes) { context[:record_degree_codes] }

          context "when record ITT subjects #{context[:record_itt_subjects]}" do
            let(:record_itt_subjects) { context[:record_itt_subjects] }

            context "when record ITT subject codes #{context[:record_itt_subject_codes]}" do
              let(:record_itt_subject_codes) { context[:record_itt_subject_codes] }

              context "when record QTS date #{context[:record_qts_date]}" do
                let(:record_qts_date) { context[:record_qts_date] }

                context "when record ITT date #{context[:record_itt_date]}" do
                  let(:record_itt_date) { context[:record_itt_date] }

                  context "when record qualification name #{context[:record_qualification_name]}" do
                    let(:record_qualification_name) { context[:record_qualification_name] }

                    it { is_expected.to eql true }
                  end
                end
              end
            end
          end
        end
      end
    end

    [
      # start of mathematics for 2021
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      # end of mathematics for 2021

      # start of physics for 2021
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: ["F300"],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["F300"],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: ["100425"],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["100425"],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      # end of physics for 2021

      # start of chemistry for 2021
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["Chemistry"],
        record_itt_subject_codes: ["F100"],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["F100"],
        record_itt_subjects: ["Chemistry"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["Chemistry"],
        record_itt_subject_codes: ["100417"],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["100417"],
        record_itt_subjects: ["Chemistry"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["Chemistry"],
        record_itt_subject_codes: ["Q100"],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      # end of chemistry for 2021

      # start of foreign_languages for 2021
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["Q100"],
        record_itt_subjects: ["Foreign Languages"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["Foreign Languages"],
        record_itt_subject_codes: ["100321"],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["100321"],
        record_itt_subjects: ["Foreign Languages"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA"
      },
      # end of foreign_languages for 2021

      # start of mathematics for 2022
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA"
      },
      # end of mathematics for 2022

      # start of mathematics for 2023
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "BA"
      },
      # end of mathematics for 2023

      # start of mathematics for 2024
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2025),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["1004030"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA"
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("1/9/2010"),
        record_qualification_name: "BA"
      }
      # end of mathematics for 2024
    ].each do |context|
      context "when claim academic year #{context[:claim_academic_year]}" do
        let(:claim_academic_year) { context[:claim_academic_year] }

        context "when record degree codes #{context[:record_degree_codes]}" do
          let(:record_degree_codes) { context[:record_degree_codes] }

          context "when record ITT subjects #{context[:record_itt_subjects]}" do
            let(:record_itt_subjects) { context[:record_itt_subjects] }

            context "when record ITT subject codes #{context[:record_itt_subject_codes]}" do
              let(:record_itt_subject_codes) { context[:record_itt_subject_codes] }

              context "when record QTS date #{context[:record_qts_date]}" do
                let(:record_qts_date) { context[:record_qts_date] }

                context "when record ITT date #{context[:record_itt_date]}" do
                  let(:record_itt_date) { context[:record_itt_date] }

                  context "when record qualification name #{context[:record_qualification_name]}" do
                    let(:record_qualification_name) { context[:record_qualification_name] }

                    it { is_expected.to eql false }
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
