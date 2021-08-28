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
    {
      degree_codes: record_degree_codes,
      itt_subject_codes: record_itt_subject_codes,
      qts_date: record_qts_date
    }
  end

  describe "#eligible?" do
    subject(:eligible?) { dqt_record.eligible? }

    [
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subject_codes: ["G100"],
        record_qts_date: Date.parse("1/9/2018")
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["G100"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2018")
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subject_codes: ["100403"],
        record_qts_date: Date.parse("1/9/2018")
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["100403"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2018")
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subject_codes: ["G100"],
        record_qts_date: Date.parse("1/9/2019")
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["G100"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2019")
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subject_codes: ["100403"],
        record_qts_date: Date.parse("1/9/2019")
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["100403"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2019")
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subject_codes: ["G100"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["G100"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subject_codes: ["100403"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["100403"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subject_codes: ["F300"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["F300"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subject_codes: ["100425"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["100425"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subject_codes: ["F100"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["F100"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subject_codes: ["100417"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["100417"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subject_codes: ["Q100"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["Q100"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subject_codes: ["100321"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["100321"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subject_codes: ["G100"],
        record_qts_date: Date.parse("1/9/2018")
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["G100"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2018")
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subject_codes: ["100403"],
        record_qts_date: Date.parse("1/9/2018")
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["100403"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2018")
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subject_codes: ["G100"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["G100"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subject_codes: ["100403"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["100403"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subject_codes: ["F300"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["F300"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subject_codes: ["100425"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["100425"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subject_codes: ["F100"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["F100"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subject_codes: ["100417"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["100417"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subject_codes: ["Q100"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["Q100"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subject_codes: ["100321"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["100321"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subject_codes: ["G100"],
        record_qts_date: Date.parse("1/9/2019")
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["G100"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2019")
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subject_codes: ["100403"],
        record_qts_date: Date.parse("1/9/2019")
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["100403"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2019")
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subject_codes: ["G100"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["G100"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subject_codes: ["100403"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["100403"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subject_codes: ["F300"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["F300"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subject_codes: ["100425"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["100425"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subject_codes: ["F100"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["F100"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subject_codes: ["100417"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["100417"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subject_codes: ["Q100"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["Q100"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subject_codes: ["100321"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["100321"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      }
    ].each do |context|
      context "when claim academic year #{context[:claim_academic_year]}" do
        let(:claim_academic_year) { context[:claim_academic_year] }

        context "when record degree codes #{context[:record_degree_codes]}" do
          let(:record_degree_codes) { context[:record_degree_codes] }

          context "when record ITT subject codes #{context[:record_itt_subject_codes]}" do
            let(:record_itt_subject_codes) { context[:record_itt_subject_codes] }

            context "when record QTS date #{context[:record_qts_date]}" do
              let(:record_qts_date) { context[:record_qts_date] }

              it { is_expected.to eql true }
            end
          end
        end
      end
    end

    [
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subject_codes: ["G100"],
        record_qts_date: Date.parse("1/9/2019")
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["G100"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2019")
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subject_codes: ["100403"],
        record_qts_date: Date.parse("1/9/2019")
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["100403"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2019")
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subject_codes: ["G100"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["G100"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subject_codes: ["100403"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["100403"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subject_codes: ["F300"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["F300"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subject_codes: ["100425"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["100425"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subject_codes: ["F100"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["F100"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subject_codes: ["100417"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["100417"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subject_codes: ["Q100"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["Q100"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subject_codes: ["100321"],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: ["100321"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2020")
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subject_codes: ["G100"],
        record_qts_date: Date.parse("1/9/2018")
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["G100"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2018")
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subject_codes: ["100403"],
        record_qts_date: Date.parse("1/9/2018")
      },
      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: ["100403"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2018")
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subject_codes: ["G100"],
        record_qts_date: Date.parse("1/9/2019")
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["G100"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2019")
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: [],
        record_itt_subject_codes: ["100403"],
        record_qts_date: Date.parse("1/9/2019")
      },
      {
        claim_academic_year: AcademicYear.new(2023),
        record_degree_codes: ["100403"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2019")
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subject_codes: ["G100"],
        record_qts_date: Date.parse("1/9/2018")
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["G100"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2018")
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: [],
        record_itt_subject_codes: ["100403"],
        record_qts_date: Date.parse("1/9/2018")
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["100403"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2018")
      },
      {
        claim_academic_year: AcademicYear.new(2025),
        record_degree_codes: ["100403"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2018")
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["1004030"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2018")
      },
      {
        claim_academic_year: AcademicYear.new(2024),
        record_degree_codes: ["100403"],
        record_itt_subject_codes: [],
        record_qts_date: Date.parse("1/9/2010")
      }
    ].each do |context|
      context "when claim academic year #{context[:claim_academic_year]}" do
        let(:claim_academic_year) { context[:claim_academic_year] }

        context "when record degree codes #{context[:record_degree_codes]}" do
          let(:record_degree_codes) { context[:record_degree_codes] }

          context "when record ITT subject codes #{context[:record_itt_subject_codes]}" do
            let(:record_itt_subject_codes) { context[:record_itt_subject_codes] }

            context "when record QTS date #{context[:record_qts_date]}" do
              let(:record_qts_date) { context[:record_qts_date] }

              it { is_expected.to eql false }
            end
          end
        end
      end
    end
  end
end
