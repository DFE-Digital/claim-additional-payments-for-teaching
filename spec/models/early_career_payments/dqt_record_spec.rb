require "rails_helper"

RSpec.describe EarlyCareerPayments::DqtRecord do
  subject(:dqt_record) do
    described_class.new(
      record,
      claim
    )
  end

  let(:claim) do
    build(
      :claim,
      policy: EarlyCareerPayments,
      academic_year: claim_academic_year,
      eligibility: eligibility
    )
  end

  let(:eligibility) do
    build(
      :early_career_payments_eligibility,
      :eligible,
      eligible_itt_subject: eligible_itt_subject,
      qualification: qualification,
      itt_academic_year: itt_academic_year
    )
  end

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
      }
      # end of QTS award date is before ITT start date for non postgrad
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
      }
      # end of QTS award date is equal to ITT start date for postgrad
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
end
