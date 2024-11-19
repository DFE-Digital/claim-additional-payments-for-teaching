require "rails_helper"

RSpec.describe Policies::EarlyCareerPayments::DqtRecord do
  before do
    create(:journey_configuration, :additional_payments)
  end

  subject(:dqt_record) { described_class.new(record, claim) }

  let(:eligible_itt_subject) { :mathematics }
  let(:qualification) { :undergraduate_itt }
  let(:itt_academic_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2018)) }

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

  let(:claim) do
    OpenStruct.new(
      {
        qualification: qualification,
        itt_academic_year: itt_academic_year,
        academic_year: claim_academic_year,
        eligible_itt_subject: eligible_itt_subject
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
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("2/9/2018"),
        record_qualification_name: "Degree",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA (Hons)",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("2/9/2018"),
        record_qualification_name: "Degree Equivalent (this will include foreign qualifications)",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA (Hons) Combined Studies/Education of the Deaf",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "EEA",
        eligible_itt_subject: :mathematics,
        qualification: :overseas_recognition,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA/Education (QTS)",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("2/9/2018"),
        record_qualification_name: nil,
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
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
        record_qualification_name: "BEd",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("2/9/2019"),
        record_qualification_name: "Flexible - PGCE",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "BEd (Hons)",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("2/9/2019"),
        record_qualification_name: "Flexible - ProfGCE",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "BSc",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("2/9/2019"),
        record_qualification_name: "Graduate Certificate in Education",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "BSc (Hons)",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("2/9/2019"),
        record_qualification_name: "Graduate Diploma",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BSc (Hons) with Intercalated PGCE",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2020"),
        record_qts_date: Date.parse("2/9/2020"),
        record_qualification_name: "GTP",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BSc/Education (QTS)",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2020"),
        record_qts_date: Date.parse("2/9/2020"),
        record_qualification_name: "Masters, not by research",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "Undergraduate Master of Teaching",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2020"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "Northern Ireland",
        eligible_itt_subject: :mathematics,
        qualification: :overseas_recognition,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2020"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "OTT",
        eligible_itt_subject: :mathematics,
        qualification: :overseas_recognition,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
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
        record_qualification_name: "BA",
        eligible_itt_subject: :physics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: ["F300"],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("31/12/2020"),
        record_qualification_name: "OTT Recognition",
        eligible_itt_subject: :physics,
        qualification: :overseas_recognition,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["F300"],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :physics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["F300"],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2020"),
        record_qts_date: Date.parse("2/9/2020"),
        record_qualification_name: "Postgraduate Certificate in Education",
        eligible_itt_subject: :physics,
        qualification: :postgraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: ["100425"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :physics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: ["100425"],
        record_itt_date: Date.parse("1/9/2020"),
        record_qts_date: Date.parse("2/9/2020"),
        record_qualification_name: "Postgraduate Certificate in Education (Flexible)",
        eligible_itt_subject: :physics,
        qualification: :postgraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["100425"],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :physics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["100425"],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2020"),
        record_qts_date: Date.parse("2/9/2020"),
        record_qualification_name: "Postgraduate Diploma in Education",
        eligible_itt_subject: :physics,
        qualification: :postgraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
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
        record_qualification_name: "BA",
        eligible_itt_subject: :chemistry,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: ["F100"],
        record_itt_date: Date.parse("1/9/2020"),
        record_qts_date: Date.parse("2/9/2020"),
        record_qualification_name: "Professional Graduate Certificate in Education",
        eligible_itt_subject: :chemistry,
        qualification: :postgraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["F100"],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :chemistry,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["F100"],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2020"),
        record_qts_date: Date.parse("2/9/2020"),
        record_qualification_name: "Professional Graduate Diploma in Education",
        eligible_itt_subject: :chemistry,
        qualification: :postgraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: ["100417"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :chemistry,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: ["100417"],
        record_itt_date: Date.parse("10/05/2020"),
        record_qts_date: Date.parse("07/06/2021"),
        record_qualification_name: "QTS Assessment only",
        eligible_itt_subject: :chemistry,
        qualification: :assessment_only,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["100417"],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :chemistry,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["100417"],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("17/05/2021"),
        record_qualification_name: "QTS Award only",
        eligible_itt_subject: :chemistry,
        qualification: :assessment_only,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      # end of chemistry for 2022

      # start of foreign_languages for 2022
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["French language"],
        record_itt_subject_codes: ["Q100"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :foreign_languages,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["French language"],
        record_itt_subject_codes: ["Q100"],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "Scotland",
        eligible_itt_subject: :foreign_languages,
        qualification: :overseas_recognition,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["Q100"],
        record_itt_subjects: ["French language"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :foreign_languages,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["Q100"],
        record_itt_subjects: ["French language"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2020"),
        record_qts_date: Date.parse("2/9/2020"),
        record_qualification_name: "Teach First",
        eligible_itt_subject: :foreign_languages,
        qualification: :postgraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["French language"],
        record_itt_subject_codes: ["100321"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :foreign_languages,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["French language"],
        record_itt_subject_codes: ["100321"],
        record_itt_date: Date.parse("1/9/2020"),
        record_qts_date: Date.parse("2/9/2020"),
        record_qualification_name: "Teach First (TNP)",
        eligible_itt_subject: :foreign_languages,
        qualification: :postgraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["100321"],
        record_itt_subjects: ["French language"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :foreign_languages,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["100321"],
        record_itt_subjects: ["French language"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2020"),
        record_qts_date: Date.parse("2/9/2020"),
        record_qualification_name: "Teachers Certificate",
        eligible_itt_subject: :foreign_languages,
        qualification: :postgraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
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
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("2/9/2018"),
        record_qualification_name: "Unknown",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
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
        record_qualification_name: "BA",
        eligible_itt_subject: :physics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["F300"],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :physics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: ["100425"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :physics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["100425"],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :physics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
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
        record_qualification_name: "BA",
        eligible_itt_subject: :chemistry,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["F100"],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :chemistry,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: ["100417"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :chemistry,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["100417"],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :chemistry,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      # end of chemistry for 2023

      # start of foreign_languages for 2023
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["French language"],
        record_itt_subject_codes: ["Q100"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :foreign_languages,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["Q100"],
        record_itt_subjects: ["French language"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :foreign_languages,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["French language"],
        record_itt_subject_codes: ["100321"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :foreign_languages,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["100321"],
        record_itt_subjects: ["French language"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :foreign_languages,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
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
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
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
        record_qualification_name: "BA",
        eligible_itt_subject: :physics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["F300"],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :physics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: ["100425"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :physics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["100425"],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :physics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
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
        record_qualification_name: "BA",
        eligible_itt_subject: :chemistry,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["F100"],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :chemistry,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: ["100417"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :chemistry,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["100417"],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :chemistry,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      # end of chemistry for 2024

      # start of foreign_languages for 2024
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subjects: ["French language"],
        record_itt_subject_codes: ["Q100"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :foreign_languages,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["Q100"],
        record_itt_subjects: ["French language"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :foreign_languages,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subjects: ["French language"],
        record_itt_subject_codes: ["100321"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :foreign_languages,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["100321"],
        record_itt_subjects: ["French language"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :foreign_languages,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      # end of foreign_languages for 2024

      # start of multiple ITT subjects/codes with at least one valid
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["biology", "chemistry"],
        record_itt_subject_codes: ["100346", "100417"],
        record_itt_date: Date.parse("3/9/2010"),
        record_qts_date: Date.parse("6/10/2020"),
        record_qualification_name: "Scotland",
        eligible_itt_subject: :chemistry,
        qualification: :overseas_recognition,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["biology", "chemistry"],
        record_itt_subject_codes: ["100417"],
        record_itt_date: Date.parse("3/9/2010"),
        record_qts_date: Date.parse("6/10/2020"),
        record_qualification_name: "Scotland",
        eligible_itt_subject: :chemistry,
        qualification: :overseas_recognition,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["biology", "chemistry"],
        record_itt_subject_codes: ["100346"],
        record_itt_date: Date.parse("3/9/2010"),
        record_qts_date: Date.parse("6/10/2020"),
        record_qualification_name: "Scotland",
        eligible_itt_subject: :chemistry,
        qualification: :overseas_recognition,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["biology", "chemistry"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("3/9/2010"),
        record_qts_date: Date.parse("6/10/2020"),
        record_qualification_name: "Scotland",
        eligible_itt_subject: :chemistry,
        qualification: :overseas_recognition,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["physics", "mathematics"],
        record_itt_subject_codes: ["100425", "100403"],
        record_itt_date: Date.parse("3/9/2019"),
        record_qts_date: Date.parse("7/12/2020"),
        record_qualification_name: "QTS Award",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100425", "100403"],
        record_itt_date: Date.parse("3/9/2019"),
        record_qts_date: Date.parse("7/12/2020"),
        record_qualification_name: "QTS Award",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
      },
      # end of multiple ITT subjects/codes with at least one valid

      # start of testing for HECOS/JAC Names for 2021
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["Applied Mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("31/8/2019"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["G1100"],
        record_itt_subjects: ["Applied Mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("31/8/2019"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["Applied Mathematics"],
        record_itt_subject_codes: ["G1100"],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("31/8/2019"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      # end of testing for HECOS/JAC Names for 2021

      # start of QTS award date is before ITT start date for non postgrad
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["Applied Mathematics"],
        record_itt_subject_codes: ["G1100"],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("31/8/2019"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      # end of QTS award date is before ITT start date for non postgrad

      # start of PG ITT year 2-week allowance: ITT start date treated as falling inside following AY (2023)
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("18/8/2018"), # deemed to fall within 2018/19 AY rather than 2017/18
        record_qts_date: Date.parse("31/12/2018"),
        record_qualification_name: "Degree",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        # user selects the following and eligible ITT AY that matches our ITT year calculation as well:
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("31/8/2018"), # deemed to fall within 2018/19 AY rather than 2017/18
        record_qts_date: Date.parse("31/12/2018"),
        record_qualification_name: "Degree",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        # user selects the following and eligible ITT AY that matches our ITT year calculation as well:
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("18/8/2020"), # deemed to fall within 2020/21 AY rather than 2019/20
        record_qts_date: Date.parse("31/12/2020"),
        record_qualification_name: "Degree",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        # user selects the following and eligible ITT AY that matches our ITT year calculation as well:
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("31/8/2020"), # deemed to fall within 2020/21 AY rather than 2019/20
        record_qts_date: Date.parse("31/12/2020"),
        record_qualification_name: "Degree",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        # user selects the following and eligible ITT AY that matches our ITT year calculation as well:
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      # end of PG ITT year 2-week allowance: ITT start date treated as falling inside following AY (2023)

      # start of PG ITT year 2-week allowance: ITT start date treated as falling inside following AY (2024)
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("18/8/2019"), # deemed to fall within 2019/20 AY rather than 2018/19
        record_qts_date: Date.parse("31/12/2019"),
        record_qualification_name: "Degree",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        # user selects the following and eligible ITT AY that matches our ITT year calculation as well:
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("31/8/2019"), # deemed to fall within 2019/20 AY rather than 2018/19
        record_qts_date: Date.parse("31/12/2019"),
        record_qualification_name: "Degree",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        # user selects the following and eligible ITT AY that matches our ITT year calculation as well:
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("18/8/2020"), # deemed to fall within 2019/20 AY rather than 2018/19
        record_qts_date: Date.parse("31/12/2020"),
        record_qualification_name: "Degree",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        # user selects the following and eligible ITT AY that matches our ITT year calculation as well:
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("31/8/2020"), # deemed to fall within 2019/20 AY rather than 2018/19
        record_qts_date: Date.parse("31/12/2020"),
        record_qualification_name: "Degree",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        # user selects the following and eligible ITT AY that matches our ITT year calculation as well:
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      }
      # end of PG ITT year 2-week allowance: ITT start date treated as falling inside following AY (2024)
    ].each do |context|
      context "when claim academic year #{context[:claim_academic_year]}" do
        let(:claim_academic_year) { context[:claim_academic_year] }

        context "when record degree codes #{context[:record_degree_codes]}" do
          let(:record_degree_codes) { context[:record_degree_codes] }

          context "when record ITT subjects #{context[:record_itt_subjects]}" do
            let(:record_itt_subjects) { context[:record_itt_subjects] }
            let(:eligible_itt_subject) { context[:eligible_itt_subject] }
            let(:qualification) { context[:qualification] }
            let(:itt_academic_year) { context[:itt_academic_year] }

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
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
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
        record_qualification_name: "BA",
        eligible_itt_subject: :physics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["F300"],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :physics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: ["100425"],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :physics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["100425"],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :physics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
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
        record_qualification_name: "BA",
        eligible_itt_subject: :chemistry,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["F100"],
        record_itt_subjects: ["Chemistry"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :chemistry,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["Chemistry"],
        record_itt_subject_codes: ["100417"],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :chemistry,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["100417"],
        record_itt_subjects: ["Chemistry"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :chemistry,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["Chemistry"],
        record_itt_subject_codes: ["Q100"],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :chemistry,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      # end of chemistry for 2021

      # start of foreign_languages for 2021
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["Q100"],
        record_itt_subjects: ["French language"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :foreign_languages,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["French language"],
        record_itt_subject_codes: ["100321"],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :foreign_languages,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["100321"],
        record_itt_subjects: ["French language"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :foreign_languages,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
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
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
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
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2018"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
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
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["G100"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      {
        claim_academic_year: AcademicYear.new(2025),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["1004030"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["100403"],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      # end of mathematics for 2024

      # start of ITT subjects that don't match the selected subject
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA",
        eligible_itt_subject: :physics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["100425"],
        record_itt_subjects: ["physics"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2020"),
        record_qts_date: Date.parse("2/9/2020"),
        record_qualification_name: "Postgraduate Diploma in Education",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["chemistry"],
        record_itt_subject_codes: ["F100"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :physics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["French language"],
        record_itt_subject_codes: ["100321"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :physics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      # end of ITT subjects that don't match the selected subject

      # start of qualifications that don't match the selected qualification
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("2/9/2018"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2017))
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "Postgraduate Certificate in Education",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      # end of qualifications that don't match the selected qualification

      # start of ITT/QTS years that don't match the selected year
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics,
        qualification: :undergraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2017))
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("2/9/2018"),
        record_qualification_name: "Postgraduate Certificate in Education",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      # end of ITT/QTS years that don't match the selected year

      # start of QTS award date is before ITT start date for postgrad
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["Applied Mathematics"],
        record_itt_subject_codes: ["G1100"],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("31/8/2019"),
        record_qualification_name: "Degree",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      # end of QTS award date is before ITT start date for postgrad

      # start of QTS award date is equal to ITT start date for postgrad
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["Applied Mathematics"],
        record_itt_subject_codes: ["G1100"],
        record_itt_date: Date.parse("1/9/2019"),
        record_qts_date: Date.parse("1/9/2019"),
        record_qualification_name: "Degree",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      # end of QTS award date is equal to ITT start date for postgrad

      # start of PG ITT year 2-week allowance: ITT start date treated as falling inside following AY (2023)
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("18/8/2019"), # deemed to fall within 2019/20 AY rather than 2018/19
        record_qts_date: Date.parse("31/12/2019"),
        record_qualification_name: "Degree",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        # user selects the previous and eligible ITT AY that does NOT match our ITT year calculation:
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("31/8/2019"), # deemed to fall within 2019/20 AY rather than 2018/19
        record_qts_date: Date.parse("31/12/2019"),
        record_qualification_name: "Degree",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        # user selects the previous and eligible ITT AY that does NOT match our ITT year calculation:
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("18/8/2021"), # deemed to fall within 2021/22 AY rather than 2020/21
        record_qts_date: Date.parse("31/12/2021"),
        record_qualification_name: "Degree",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        # user selects the previous and eligible ITT AY that does NOT match our ITT year calculation:
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("31/8/2021"), # deemed to fall within 2021/22 AY rather than 2020/21
        record_qts_date: Date.parse("31/12/2021"),
        record_qualification_name: "Degree",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        # user selects the previous and eligible ITT AY that does NOT match our ITT year calculation:
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      # end of PG ITT year 2-week allowance: ITT start date treated as falling inside following AY (2023)

      # start of PG ITT year 2-week allowance: ITT start date treated as falling inside following AY (2024)
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("18/8/2020"), # deemed to fall within 2020/21 AY rather than 2019/20
        record_qts_date: Date.parse("31/12/2020"),
        record_qualification_name: "Degree",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        # user selects the previous and eligible ITT AY that does NOT match our ITT year calculation:
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("31/8/2020"), # deemed to fall within 2020/21 AY rather than 2019/20
        record_qts_date: Date.parse("31/12/2020"),
        record_qualification_name: "Degree",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        # user selects the previous and eligible ITT AY that does NOT match our ITT year calculation:
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("18/8/2021"), # deemed to fall within 2021/22 AY rather than 2020/21
        record_qts_date: Date.parse("31/12/2021"),
        record_qualification_name: "Degree",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        # user selects the previous and eligible ITT AY that does NOT match our ITT year calculation:
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["100403"],
        record_itt_date: Date.parse("31/8/2021"), # deemed to fall within 2021/22 AY rather than 2020/21
        record_qts_date: Date.parse("31/12/2021"),
        record_qualification_name: "Degree",
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        # user selects the previous and eligible ITT AY that does NOT match our ITT year calculation:
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      }
      # end of PG ITT year 2-week allowance: ITT start date treated as falling inside following AY (2024)
    ].each do |context|
      context "when claim academic year #{context[:claim_academic_year]}" do
        let(:claim_academic_year) { context[:claim_academic_year] }

        context "when record degree codes #{context[:record_degree_codes]}" do
          let(:record_degree_codes) { context[:record_degree_codes] }

          context "when record ITT subjects #{context[:record_itt_subjects]}" do
            let(:record_itt_subjects) { context[:record_itt_subjects] }
            let(:eligible_itt_subject) { context[:eligible_itt_subject] }
            let(:qualification) { context[:qualification] }
            let(:itt_academic_year) { context[:itt_academic_year] }

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

  describe "#eligible_induction?" do
    subject(:eligible_induction?) { dqt_record.eligible_induction? }

    let(:record) do
      OpenStruct.new(
        itt_year: calculated_itt_year,
        induction_start_date: Date.parse("1/9/2017"),
        induction_completion_date: Date.parse("1/9/2018"),
        induction_status: "Pass"
      )
    end
    let(:calculated_itt_year) { AcademicYear.new(2021) }
    let(:claim_academic_year) { AcademicYear.new(2023) }
    let(:induction_data) do
      instance_double(Policies::EarlyCareerPayments::InductionData, eligible?: "true_or_false")
    end

    let(:expected_attributes) { record.to_h.except(:induction_completion_date) }
    let(:expected_result) { induction_data.eligible? }

    before do
      allow(dqt_record).to receive(:itt_year).and_return(calculated_itt_year)
      allow(Policies::EarlyCareerPayments::InductionData).to receive(:new)
        .with(expected_attributes)
        .and_return(induction_data)
    end

    it { expect(eligible_induction?).to eq(expected_result) }
  end

  describe "#eligible_itt_subject_for_claim" do
    let(:record) { OpenStruct.new(itt_subjects:) }

    context "with a valid ITT year" do
      before do
        allow(Policies::EarlyCareerPayments).to(
          receive(:current_and_future_subject_symbols)
          .and_return(eligible_subjects)
        )
      end

      let(:claim_academic_year) { AcademicYear.new(2023) }
      let(:eligible_subjects) { [:mathematics] }

      context "when the record returns a valid subject" do
        let(:itt_subjects) { ["Applied Mathematics"] }

        it "returns the valid subject" do
          expect(dqt_record.eligible_itt_subject_for_claim).to eq(:mathematics)
        end
      end

      context "when the record returns multiple valid subjects" do
        let(:itt_subjects) { ["Applied Mathematics", "Applied Physics"] }
        let(:eligible_subjects) { [:physics, :mathematics, :computing] }

        it "returns the first valid subject" do
          expect(dqt_record.eligible_itt_subject_for_claim).to eq(:mathematics)
        end
      end

      context "when the record returns an invalid subject" do
        let(:itt_subjects) { ["test"] }

        it "returns none_of_the_above" do
          expect(dqt_record.eligible_itt_subject_for_claim).to eq(:none_of_the_above)
        end
      end

      context "when the record returns valid and invalid subjects" do
        let(:itt_subjects) { ["invalid", "Applied Mathematics", "test", "Applied Physics"] }

        it "returns the first valid subject" do
          expect(dqt_record.eligible_itt_subject_for_claim).to eq(:mathematics)
        end
      end

      context "when the record returns nil" do
        let(:itt_subjects) { nil }

        it "returns nil" do
          expect(dqt_record.eligible_itt_subject_for_claim).to eq(:none_of_the_above)
        end
      end

      context "when the record has no ITT year" do
        let(:record_qts_date) { nil }
        let(:itt_subjects) { ["Applied Mathematics"] }

        context "when the Claim has no ITT year" do
          let(:itt_academic_year) { nil }

          it "returns nil" do
            expect(dqt_record.eligible_itt_subject_for_claim).to eq(:none_of_the_above)
          end
        end

        context "when the Claim has an ITT year" do
          it "returns a subject based on the claim academic year" do
            expect(dqt_record.eligible_itt_subject_for_claim).to eq(:mathematics)
          end
        end
      end
    end

    context "with an invalid ITT year" do
      let(:claim_academic_year) { AcademicYear.for(Date.new(1666, 1, 1)) }
      let(:itt_subjects) { ["mathematics"] }

      before do
        allow(Policies::EarlyCareerPayments).to receive(:current_and_future_subject_symbols)
          .and_raise(StandardError.new("ITT year"))
      end

      it "returns none_of_the_above" do
        expect(dqt_record.eligible_itt_subject_for_claim).to eq(:none_of_the_above)
      end
    end
  end

  describe "#itt_academic_year_for_claim" do
    before do
      allow(Policies::EarlyCareerPayments).to(
        receive(:selectable_itt_years_for_claim_year).and_return(eligible_years)
      )
    end

    let(:record) do
      OpenStruct.new(
        qualification_name: "BA",
        qts_award_date:
      )
    end

    let(:claim_year) { 2023 }
    let(:claim_academic_year) { AcademicYear.new(claim_year) }

    let(:eligible_years) { (AcademicYear.new(claim_year - 5)...AcademicYear.new(claim_year)).to_a }

    context "when the record returns an eligible date" do
      let(:qts_award_date) { Date.new(claim_year, 1, 1) }

      it "returns the academic year" do
        expect(dqt_record.itt_academic_year_for_claim).to eq(AcademicYear.for(qts_award_date))
      end
    end

    context "when the record returns an ineligible date" do
      let(:qts_award_date) { Date.new(claim_year - 10, 12, 1) }

      it "returns a blank academic year" do
        expect(dqt_record.itt_academic_year_for_claim).to eq(AcademicYear.new)
      end
    end

    context "when the record returns nil" do
      let(:qts_award_date) { nil }

      it "returns nil" do
        expect(dqt_record.itt_academic_year_for_claim).to be_nil
      end
    end
  end

  describe "#has_no_data_for_claim?" do
    let(:record) do
      OpenStruct.new(
        qualification_name: "BA"
      )
    end
    let(:claim_year) { 2023 }
    let(:claim_academic_year) { AcademicYear.new(claim_year) }

    context "when one or more required data are present" do
      before { allow(dqt_record).to receive(:eligible_itt_subject_for_claim).and_return("test") }

      it { is_expected.not_to be_has_no_data_for_claim }
    end

    context "when all required data are not present" do
      before do
        allow(dqt_record).to receive(:eligible_itt_subject_for_claim).and_return(nil)
        allow(dqt_record).to receive(:itt_academic_year_for_claim).and_return(nil)
        allow(dqt_record).to receive(:route_into_teaching).and_return(nil)
      end

      it { is_expected.to be_has_no_data_for_claim }
    end
  end
end
