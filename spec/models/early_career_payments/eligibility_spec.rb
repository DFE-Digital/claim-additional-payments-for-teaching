# frozen_string_literal: true

require "rails_helper"

RSpec.describe EarlyCareerPayments::Eligibility, type: :model do
  describe "#policy" do
    let(:early_career_payments_eligibility) { build(:early_career_payments_eligibility) }

    it "has a policy class of 'EarlyCareerPayments'" do
      expect(early_career_payments_eligibility.policy).to eq EarlyCareerPayments
    end
  end

  describe "qualification attribute" do
    it "rejects invalid values" do
      expect { EarlyCareerPayments::Eligibility.new(qualification: "non-existance") }.to raise_error(ArgumentError)
    end

    it "has handily named boolean methods for the possible values" do
      eligibility = EarlyCareerPayments::Eligibility.new(qualification: "postgraduate_itt")

      expect(eligibility.postgraduate_itt?).to eq true
      expect(eligibility.undergraduate_itt?).to eq false
      expect(eligibility.assessment_only?).to eq false
      expect(eligibility.overseas_recognition?).to eq false
    end
  end

  describe "#qualification_name" do
    context "when qualificaton is 'postgraduate_itt' or 'undergraduate_itt'" do
      eligibility = EarlyCareerPayments::Eligibility.new(qualification: "postgraduate_itt")

      it "returns the qualification in the format '<qualification> initial teacher training (ITT)'" do
        expect(eligibility.qualification_name).to eq "postgraduate initial teacher training (ITT)"
      end
    end

    context "when qualification is 'assessment_only'" do
      eligibility = EarlyCareerPayments::Eligibility.new(qualification: "assessment_only")

      it "returns the qualification in a humanized for that is lowercase" do
        expect(eligibility.qualification_name).to eq "assessment only"
      end
    end

    context "when qualification is 'overseas recognition'" do
      eligibility = EarlyCareerPayments::Eligibility.new(qualification: "overseas_recognition")

      it "returns the qualification in a humanized for that is lowercase" do
        expect(eligibility.qualification_name).to eq "overseas recognition qualification"
      end
    end
  end

  describe "eligible_itt_subject attribute" do
    it "rejects invalid values" do
      expect { EarlyCareerPayments::Eligibility.new(eligible_itt_subject: "not-in-list-of-options") }.to raise_error(ArgumentError)
    end

    it "has handily named boolean methods for the possible values" do
      eligibility = EarlyCareerPayments::Eligibility.new(eligible_itt_subject: "foreign_languages")

      expect(eligibility.itt_subject_foreign_languages?).to eq true
      expect(eligibility.itt_subject_chemistry?).to eq false
      expect(eligibility.itt_subject_mathematics?).to eq false
      expect(eligibility.itt_subject_physics?).to eq false
      expect(eligibility.itt_subject_none_of_the_above?).to eq false
    end
  end

  describe "#eligible_later?" do
    let!(:claim) { build_stubbed(:claim, academic_year: claim_academic_year, eligibility: eligibility) }
    let(:claim_academic_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2021)) }
    let(:eligibility) do
      build(
        :early_career_payments_eligibility,
        eligible_itt_subject: itt_subject,
        itt_academic_year: itt_academic_year
      )
    end

    context "when claim is eligible later" do
      [
        {itt_subject: "mathematics", itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))},
        {itt_subject: "mathematics", itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))},
        {itt_subject: "physics", itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))},
        {itt_subject: "chemistry", itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))},
        {itt_subject: "foreign_languages", itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))}
      ].each do |context|
        context "with ITT subject #{context[:itt_subject].to_s.humanize}" do
          let(:itt_subject) { context[:itt_subject] }

          context "with ITT academic year #{context[:itt_academic_year]}" do
            let(:itt_academic_year) { context[:itt_academic_year] }

            it "returns true" do
              expect(eligibility.eligible_later?).to eql true
            end
          end
        end
      end
    end

    context "when claim is not eligible later" do
      let(:itt_subject) { "chemistry" }
      let(:itt_academic_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2018)) }

      it "returns false" do
        expect(eligibility.eligible_later?).to eql false
      end
    end
  end

  describe "#ineligible?" do
    before do
      build_stubbed(
        :claim,
        academic_year: claim_academic_year,
        eligibility: eligibility
      )
    end
    let(:claim_academic_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2022)) }
    let(:eligibility) do
      build(
        :early_career_payments_eligibility,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018)),
        eligible_itt_subject: :mathematics
      )
    end

    it "returns false when the eligibility cannot be determined" do
      expect(eligibility.ineligible?).to eql false
    end

    [
      {policy_year: AcademicYear::Type.new.serialize(AcademicYear.new(2021)), expected_result: false},
      {policy_year: AcademicYear::Type.new.serialize(AcademicYear.new(2022)), expected_result: true}
    ].each do |scenario|
      context "with a policy configuration for #{scenario[:policy_year]}" do
        before do
          @ecp_policy_date = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
          PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: scenario[:policy_year])
        end

        after do
          PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: @ecp_policy_date)
        end

        it "returns true when the NQT acdemic year was not the year after the ITT" do
          eligibility.nqt_in_academic_year_after_itt = true
          expect(eligibility.ineligible?).to eql false

          eligibility.nqt_in_academic_year_after_itt = false
          expect(eligibility.ineligible?).to eql scenario[:expected_result]
        end
      end
    end

    it "returns true when claimant is a supply teacher without a contract of at least one term" do
      eligibility.employed_as_supply_teacher = true
      eligibility.has_entire_term_contract = false
      expect(eligibility.ineligible?).to eql true

      eligibility.has_entire_term_contract = true
      expect(eligibility.ineligible?).to eql false
    end

    it "returns true when claimant is a supply teacher employed by a private agency" do
      eligibility.employed_as_supply_teacher = true
      eligibility.employed_directly = false
      expect(eligibility.ineligible?).to eql true

      eligibility.employed_as_supply_teacher = true
      eligibility.employed_directly = true
      expect(eligibility.ineligible?).to eql false
    end

    context "poor performance" do
      it "returns true when subject to formal performance action" do
        eligibility.subject_to_formal_performance_action = true
        eligibility.subject_to_disciplinary_action = false
        expect(eligibility.ineligible?).to eql true

        eligibility.subject_to_formal_performance_action = false
        eligibility.subject_to_disciplinary_action = false
        expect(eligibility.ineligible?).to eql false
      end

      it "returns true when subject to disciplinary action" do
        eligibility.subject_to_formal_performance_action = false
        eligibility.subject_to_disciplinary_action = true
        expect(eligibility.ineligible?).to eql true

        eligibility.subject_to_formal_performance_action = false
        eligibility.subject_to_disciplinary_action = false
        expect(eligibility.ineligible?).to eql false
      end

      it "returns true when subject to formal performance and disciplinary action" do
        eligibility.subject_to_formal_performance_action = true
        eligibility.subject_to_disciplinary_action = true
        expect(eligibility.ineligible?).to eql true

        eligibility.subject_to_formal_performance_action = false
        eligibility.subject_to_disciplinary_action = false
        expect(eligibility.ineligible?).to eql false
      end
    end

    it "returns true when none of the eligible ITT courses were taken" do
      eligibility.eligible_itt_subject = :none_of_the_above
      expect(eligibility.ineligible?).to eql true

      eligibility.eligible_itt_subject = :mathematics
      expect(eligibility.ineligible?).to eql false
    end

    it "returns true when still teaching now the course indentified as being eligible ITT subject" do
      eligibility.teaching_subject_now = false
      expect(eligibility.ineligible?).to eql true

      eligibility.teaching_subject_now = true
      expect(eligibility.ineligible?).to eql false
    end

    it "returns true when the ITT postgraduate start date OR ITT undergraduate complete date not in 2018 - 2019, 2019 - 2020, 2020 - 2021" do
      eligibility.itt_academic_year = AcademicYear::Type.new.serialize(AcademicYear.new)
      expect(eligibility.ineligible?).to eql true

      eligibility.itt_academic_year = AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      expect(eligibility.ineligible?).to eql false

      eligibility.itt_academic_year = AcademicYear::Type.new.serialize(AcademicYear.new(2019))
      expect(eligibility.ineligible?).to eql false

      eligibility.itt_academic_year = AcademicYear::Type.new.serialize(AcademicYear.new(2020))
      expect(eligibility.ineligible?).to eql false
    end

    [
      {itt_subject: "mathematics", itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))},
      {itt_subject: "mathematics", itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))},
      {itt_subject: "mathematics", itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))},
      {itt_subject: "physics", itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))},
      {itt_subject: "chemistry", itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))},
      {itt_subject: "foreign_languages", itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))}
    ].each do |spec|
      context "when cohort is eligible" do
        let(:claim_academic_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2021)) }

        let(:eligibility_args) do
          {
            eligible_itt_subject: spec[:itt_subject],
            itt_academic_year: spec[:itt_academic_year]
          }
        end

        let(:eligibility) { EarlyCareerPayments::Eligibility.new(eligibility_args) }

        it "returns false" do
          expect(eligibility.ineligible?).to eql false
        end
      end
    end

    [
      {itt_subject: "chemistry", itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))},
      {itt_subject: "foreign_languages", itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))}
    ].each do |spec|
      context "when cohort is ineligible" do
        let(:claim_academic_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2021)) }

        let(:eligibility_args) do
          {
            eligible_itt_subject: spec[:itt_subject],
            itt_academic_year: spec[:itt_academic_year]
          }
        end

        let(:eligibility) { EarlyCareerPayments::Eligibility.new(eligibility_args) }

        it "returns true" do
          expect(eligibility.ineligible?).to eql true
        end
      end
    end
  end

  describe "#ineligibility_reason" do
    let(:eligibility) do
      build(
        :early_career_payments_eligibility,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018)),
        eligible_itt_subject: :mathematics
      )
    end

    [
      {policy_year: AcademicYear::Type.new.serialize(AcademicYear.new(2021)), ineligibility_reason: nil},
      {policy_year: AcademicYear::Type.new.serialize(AcademicYear.new(2022)), ineligibility_reason: :generic_ineligibility}
    ].each do |scenario|
      context "with a policy configuration for #{scenario[:policy_year]}" do
        before do
          @ecp_policy_date = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
          PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: scenario[:policy_year])

          build_stubbed(
            :claim,
            academic_year: scenario[:policy_year],
            eligibility: eligibility
          )
        end

        after do
          PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: @ecp_policy_date)
        end

        it "returns a symbol indicating the reason for ineligibility" do
          eligibility.nqt_in_academic_year_after_itt = true
          expect(eligibility.ineligibility_reason).to be_nil

          eligibility.nqt_in_academic_year_after_itt = false
          expect(eligibility.ineligibility_reason).to eql scenario[:ineligibility_reason]

          expect(EarlyCareerPayments::Eligibility.new(employed_as_supply_teacher: true, has_entire_term_contract: false).ineligibility_reason).to eql :generic_ineligibility
          expect(EarlyCareerPayments::Eligibility.new(employed_as_supply_teacher: true, employed_directly: false).ineligibility_reason).to eql :generic_ineligibility
          expect(EarlyCareerPayments::Eligibility.new(subject_to_formal_performance_action: true).ineligibility_reason).to eq :generic_ineligibility
          expect(EarlyCareerPayments::Eligibility.new(subject_to_disciplinary_action: true).ineligibility_reason).to eql :generic_ineligibility
          expect(EarlyCareerPayments::Eligibility.new(subject_to_formal_performance_action: true, subject_to_disciplinary_action: true).ineligibility_reason).to eq :generic_ineligibility
          expect(EarlyCareerPayments::Eligibility.new(eligible_itt_subject: :none_of_the_above).ineligibility_reason).to eq :itt_subject_none_of_the_above
          expect(EarlyCareerPayments::Eligibility.new(teaching_subject_now: false).ineligibility_reason).to eql :not_teaching_now_in_eligible_itt_subject
          expect(EarlyCareerPayments::Eligibility.new(itt_academic_year: AcademicYear.new).ineligibility_reason).to be_nil
        end
      end
    end
  end

  describe "#award_amount" do
    [
      {
        policy_year: AcademicYear::Type.new.serialize(AcademicYear.new(2021)),
        context: {
          itt_subject: "mathematics",
          itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
        },
        expect: {
          base_amount: 5_000,
          uplift_amount: 7_500
        }
      },
      {
        policy_year: AcademicYear::Type.new.serialize(AcademicYear.new(2022)),
        context: {
          itt_subject: "mathematics",
          itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
        },
        expect: {
          base_amount: 5_000,
          uplift_amount: 7_500
        }
      },
      {
        policy_year: AcademicYear::Type.new.serialize(AcademicYear.new(2022)),
        context: {
          itt_subject: "mathematics",
          itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
        },
        expect: {
          base_amount: 2_000,
          uplift_amount: 3_000
        }
      },
      {
        policy_year: AcademicYear::Type.new.serialize(AcademicYear.new(2022)),
        context: {
          itt_subject: "physics",
          itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
        },
        expect: {
          base_amount: 2_000,
          uplift_amount: 3_000
        }
      },
      {
        policy_year: AcademicYear::Type.new.serialize(AcademicYear.new(2022)),
        context: {
          itt_subject: "chemistry",
          itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
        },
        expect: {
          base_amount: 2_000,
          uplift_amount: 3_000
        }
      },
      {
        policy_year: AcademicYear::Type.new.serialize(AcademicYear.new(2022)),
        context: {
          itt_subject: "foreign_languages",
          itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
        },
        expect: {
          base_amount: 2_000,
          uplift_amount: 3_000
        }
      },
      {
        policy_year: AcademicYear::Type.new.serialize(AcademicYear.new(2023)),
        context: {
          itt_subject: "mathematics",
          itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
        },
        expect: {
          base_amount: 5_000,
          uplift_amount: 7_500
        }
      },
      {
        policy_year: AcademicYear::Type.new.serialize(AcademicYear.new(2023)),
        context: {
          itt_subject: "mathematics",
          itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
        },
        expect: {
          base_amount: 2_000,
          uplift_amount: 3_000
        }
      },
      {
        policy_year: AcademicYear::Type.new.serialize(AcademicYear.new(2023)),
        context: {
          itt_subject: "physics",
          itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
        },
        expect: {
          base_amount: 2_000,
          uplift_amount: 3_000
        }
      },
      {
        policy_year: AcademicYear::Type.new.serialize(AcademicYear.new(2023)),
        context: {
          itt_subject: "chemistry",
          itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
        },
        expect: {
          base_amount: 2_000,
          uplift_amount: 3_000
        }
      },
      {
        policy_year: AcademicYear::Type.new.serialize(AcademicYear.new(2023)),
        context: {
          itt_subject: "foreign_languages",
          itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
        },
        expect: {
          base_amount: 2_000,
          uplift_amount: 3_000
        }
      },
      {
        policy_year: AcademicYear::Type.new.serialize(AcademicYear.new(2024)),
        context: {
          itt_subject: "mathematics",
          itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
        },
        expect: {
          base_amount: 5_000,
          uplift_amount: 7_500
        }
      },
      {
        policy_year: AcademicYear::Type.new.serialize(AcademicYear.new(2024)),
        context: {
          itt_subject: "mathematics",
          itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
        },
        expect: {
          base_amount: 2_000,
          uplift_amount: 3_000
        }
      },
      {
        policy_year: AcademicYear::Type.new.serialize(AcademicYear.new(2024)),
        context: {
          itt_subject: "physics",
          itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
        },
        expect: {
          base_amount: 2_000,
          uplift_amount: 3_000
        }
      },
      {
        policy_year: AcademicYear::Type.new.serialize(AcademicYear.new(2024)),
        context: {
          itt_subject: "chemistry",
          itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
        },
        expect: {
          base_amount: 2_000,
          uplift_amount: 3_000
        }
      },
      {
        policy_year: AcademicYear::Type.new.serialize(AcademicYear.new(2024)),
        context: {
          itt_subject: "foreign_languages",
          itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020))
        },
        expect: {
          base_amount: 2_000,
          uplift_amount: 3_000
        }
      }
    ].each do |spec|
      context "when cohort eligible in Claim window #{spec[:policy_year]}" do
        before do
          @ecp_policy_date = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
          PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: spec[:policy_year])
        end

        after do
          PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: @ecp_policy_date)
        end

        let(:eligibility_args) do
          {
            eligible_itt_subject: spec[:context][:itt_subject],
            itt_academic_year: spec[:context][:itt_academic_year],
            current_school: current_school_arg,
            claim: claim
          }
        end
        let(:claim) do
          build_stubbed(
            :claim,
            academic_year: spec[:policy_year]
          )
        end

        context "without uplift school" do
          let(:current_school_arg) do
            School.find(ActiveRecord::FixtureSet.identify(:hampstead_school, :uuid))
          end

          it "returns base amount" do
            expect(EarlyCareerPayments::Eligibility.new(eligibility_args).award_amount).to eq(spec[:expect][:base_amount])
          end
        end

        context "with uplift school" do
          let(:current_school_arg) do
            School.find(ActiveRecord::FixtureSet.identify(:penistone_grammar_school, :uuid))
          end

          it "returns uplift amount" do
            expect(EarlyCareerPayments::Eligibility.new(eligibility_args).award_amount).to eq(spec[:expect][:uplift_amount])
          end
        end
      end
    end

    context "when cohort ineligible" do
      let(:eligibility_args) do
        {
          eligible_itt_subject: "physics",
          itt_academic_year: "2018/2019",
          current_school: School.find(ActiveRecord::FixtureSet.identify(:hampstead_school, :uuid))
        }
      end

      it "returns 0.00" do
        expect(EarlyCareerPayments::Eligibility.new(eligibility_args).award_amount).to eq(BigDecimal("0.00"))
      end
    end

    context "without cohort" do
      let(:eligibility_args) do
        {
          current_school: School.find(ActiveRecord::FixtureSet.identify(:hampstead_school, :uuid))
        }
      end

      it "returns 0.00" do
        expect(EarlyCareerPayments::Eligibility.new(eligibility_args).award_amount).to eq(BigDecimal("0.00"))
      end
    end

    context "without school" do
      let(:eligibility_args) do
        {
          eligible_itt_subject: "mathematics",
          itt_academic_year: "2018/2019"
        }
      end

      it "returns 0.00" do
        expect(EarlyCareerPayments::Eligibility.new(eligibility_args).award_amount).to eq(BigDecimal("0.00"))
      end
    end
  end

  describe "#award_amounts" do
    [
      {
        policy_year: AcademicYear::Type.new.serialize(AcademicYear.new(2021)),
        eligible_now: [
          {
            itt_subject: "mathematics",
            itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018)),
            base_amount: 5_000,
            uplift_amount: 7_500
          }
        ],
        ineligible: [
          {
            itt_subject: "physics",
            itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018)),
            base_amount: BigDecimal("0.00"),
            uplift_amount: BigDecimal("0.00")
          }
        ]
      },
      {
        policy_year: AcademicYear::Type.new.serialize(AcademicYear.new(2022)),
        eligible_now: [
          {
            itt_subject: "mathematics",
            itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019)),
            base_amount: 5_000,
            uplift_amount: 7_500
          },
          {
            itt_subject: :mathematics,
            itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020)),
            base_amount: 2_000,
            uplift_amount: 3_000
          },
          {
            itt_subject: :physics,
            itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020)),
            base_amount: 2_000,
            uplift_amount: 3_000
          },
          {
            itt_subject: :chemistry,
            itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020)),
            base_amount: 2_000,
            uplift_amount: 3_000
          },
          {
            itt_subject: :foreign_languages,
            itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020)),
            base_amount: 2_000,
            uplift_amount: 3_000
          }
        ],
        ineligible: [
          {
            itt_subject: :chemistry,
            itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019)),
            base_amount: BigDecimal("0.00"),
            uplift_amount: BigDecimal("0.00")
          }
        ]
      },
      {
        policy_year: AcademicYear::Type.new.serialize(AcademicYear.new(2023)),
        eligible_now: [
          {
            itt_subject: :mathematics,
            itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018)),
            base_amount: 5_000,
            uplift_amount: 7_500
          },
          {
            itt_subject: "mathematics",
            itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020)),
            base_amount: 2_000,
            uplift_amount: 3_000
          },
          {
            itt_subject: "physics",
            itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020)),
            base_amount: 2_000,
            uplift_amount: 3_000
          },
          {
            itt_subject: "chemistry",
            itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020)),
            base_amount: 2_000,
            uplift_amount: 3_000
          },
          {
            itt_subject: "foreign_languages",
            itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020)),
            base_amount: 2_000,
            uplift_amount: 3_000
          }
        ],
        ineligible: [
          {
            itt_subject: :foreign_languages,
            itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018)),
            base_amount: BigDecimal("0.00"),
            uplift_amount: BigDecimal("0.00")
          }
        ]
      },
      {
        policy_year: AcademicYear::Type.new.serialize(AcademicYear.new(2024)),
        eligible_now: [
          {
            itt_subject: :mathematics,
            itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019)),
            base_amount: 5_000,
            uplift_amount: 7_500
          },
          {
            itt_subject: "mathematics",
            itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020)),
            base_amount: 2_000,
            uplift_amount: 3_000
          },
          {
            itt_subject: :physics,
            itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020)),
            base_amount: 2_000,
            uplift_amount: 3_000
          },
          {
            itt_subject: :chemistry,
            itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020)),
            base_amount: 2_000,
            uplift_amount: 3_000
          },
          {
            itt_subject: :foreign_languages,
            itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020)),
            base_amount: 2_000,
            uplift_amount: 3_000
          }
        ],
        ineligible: [
          {
            itt_subject: :mathematics,
            itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018)),
            base_amount: BigDecimal("0.00"),
            uplift_amount: BigDecimal("0.00")
          }
        ]
      }
    ].each do |example|
      context "with a policy configuration for #{example[:policy_year]} and when cohort is eligible" do
        before do
          @ecp_policy_date = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
          PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: example[:policy_year])
        end

        after do
          PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: @ecp_policy_date)
        end

        example[:eligible_now].each do |scenario|
          context "with ITT subject #{scenario[:itt_subject]} in ITT academic year #{scenario[:itt_academic_year]}" do
            before do
              build_stubbed(
                :claim,
                academic_year: example[:policy_year],
                eligibility: eligibility
              )
            end
            let(:eligibility) do
              build(
                :early_career_payments_eligibility,
                eligible_itt_subject: scenario[:itt_subject],
                itt_academic_year: scenario[:itt_academic_year]
              )
            end

            it "returns an array with the correct values" do
              expect(eligibility.award_amounts).to be_an_instance_of(Array)
              expect(eligibility.award_amounts.collect { |award_amount| [award_amount.base_amount, award_amount.uplift_amount] }).to eq [[scenario[:base_amount], scenario[:uplift_amount]]]
            end
          end
        end

        example[:ineligible].each do |scenario|
          context "when cohort ineligible (ITT subject: #{scenario[:itt_subject]}, ITT academic year: #{scenario[:itt_academic_year]})" do
            before do
              build_stubbed(
                :claim,
                academic_year: example[:policy_year],
                eligibility: eligibility
              )
            end
            let(:eligibility) do
              build(
                :early_career_payments_eligibility,
                eligible_itt_subject: scenario[:itt_subject],
                itt_academic_year: scenario[:itt_academic_year]
              )
            end

            it "returns an array with 0.00 values" do
              expect(eligibility.award_amounts).to be_an_instance_of(Array)
              expect(eligibility.award_amounts.collect { |award_amount| [award_amount.base_amount, award_amount.uplift_amount] }).to eq [[scenario[:base_amount], scenario[:uplift_amount]]]
            end
          end
        end
      end
    end

    context "without cohort" do
      it "returns hash with 0.00 values" do
        expect(EarlyCareerPayments::Eligibility.new.award_amounts).to be_an_instance_of(Array)
        expect(EarlyCareerPayments::Eligibility.new.award_amounts.collect { |award_amount| [award_amount.base_amount, award_amount.uplift_amount] }.flatten).to eq [BigDecimal("0.00"), BigDecimal("0.00")]
      end
    end
  end

  describe "#first_eligible_itt_academic_year" do
    subject(:first_eligible_itt_academic_year) do
      eligibility = build_stubbed(
        :early_career_payments_eligibility,
        eligible_itt_subject: eligible_itt_subject
      )
      build_stubbed(
        :claim,
        academic_year: claim_academic_year,
        eligibility: eligibility
      )

      eligibility.first_eligible_itt_academic_year
    end

    [
      {
        eligible_itt_subject: "mathematics",
        claim_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2021)),
        itt_academic_year: AcademicYear.new(2018)
      },
      {
        eligible_itt_subject: :physics,
        claim_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2021)),
        itt_academic_year: nil
      },
      {
        eligible_itt_subject: :chemistry,
        claim_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2021)),
        itt_academic_year: nil
      },
      {
        eligible_itt_subject: :foreign_languages,
        claim_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2021)),
        itt_academic_year: nil
      },
      {
        eligible_itt_subject: :mathematics,
        claim_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2022)),
        itt_academic_year: AcademicYear.new(2019)
      },
      {
        eligible_itt_subject: :physics,
        claim_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2022)),
        itt_academic_year: AcademicYear.new(2020)
      },
      {
        eligible_itt_subject: :chemistry,
        claim_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2022)),
        itt_academic_year: AcademicYear.new(2020)
      },
      {
        eligible_itt_subject: :foreign_languages,
        claim_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2022)),
        itt_academic_year: AcademicYear.new(2020)
      },
      {
        eligible_itt_subject: :mathematics,
        claim_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2023)),
        itt_academic_year: AcademicYear.new(2018)
      },
      {
        eligible_itt_subject: :physics,
        claim_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2023)),
        itt_academic_year: AcademicYear.new(2020)
      },
      {
        eligible_itt_subject: :chemistry,
        claim_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2023)),
        itt_academic_year: AcademicYear.new(2020)
      },
      {
        eligible_itt_subject: :foreign_languages,
        claim_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2023)),
        itt_academic_year: AcademicYear.new(2020)
      },
      {
        eligible_itt_subject: :mathematics,
        claim_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2024)),
        itt_academic_year: AcademicYear.new(2019)
      },
      {
        eligible_itt_subject: :physics,
        claim_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2024)),
        itt_academic_year: AcademicYear.new(2020)
      },
      {
        eligible_itt_subject: :chemistry,
        claim_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2024)),
        itt_academic_year: AcademicYear.new(2020)
      },
      {
        eligible_itt_subject: :foreign_languages,
        claim_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2024)),
        itt_academic_year: AcademicYear.new(2020)
      }
    ].each do |spec|
      context "with eligible ITT subject #{spec[:eligible_itt_subject]}" do
        let(:eligible_itt_subject) { spec[:eligible_itt_subject] }

        context "with claim academic year" do
          let(:claim_academic_year) { spec[:claim_academic_year] }

          it "returns ITT academic year #{spec[:itt_academic_year]}" do
            expect(first_eligible_itt_academic_year).to eq spec[:itt_academic_year]
          end
        end
      end
    end
  end

  describe "#reset_dependent_answers" do
    let!(:claim) { build_stubbed(:claim, :with_student_loan, eligibility: eligibility) }

    let(:eligibility) do
      build_stubbed(
        :early_career_payments_eligibility,
        :eligible,
        employed_as_supply_teacher: true,
        has_entire_term_contract: false,
        employed_directly: false,
        qualification: :undergraduate_itt,
        eligible_itt_subject: :none_of_the_above,
        teaching_subject_now: false
      )
    end

    it "resets 'eligible_itt_subject' when value of 'qualification' changes" do
      eligibility.qualification = :undergraduate_itt
      expect { eligibility.reset_dependent_answers }.not_to change { eligibility.attributes }

      eligibility.qualification = :postgraduate_itt
      expect { eligibility.reset_dependent_answers }
        .to change { eligibility.eligible_itt_subject }
        .from("none_of_the_above").to(nil)
    end

    it "resets 'teaching_subject_now' when value of 'qualification' changes" do
      eligibility.qualification = :undergraduate_itt
      expect { eligibility.reset_dependent_answers }.not_to change { eligibility.attributes }

      eligibility.qualification = :postgraduate_itt
      expect { eligibility.reset_dependent_answers }
        .to change { eligibility.teaching_subject_now }
        .from(false).to(nil)
    end

    it "resets 'teaching_subject_now' when value of 'eligible_itt_subject' changes" do
      eligibility.eligible_itt_subject = :none_of_the_above
      expect { eligibility.reset_dependent_answers }.not_to change { eligibility.attributes }

      eligibility.eligible_itt_subject = :foreign_languages
      expect { eligibility.reset_dependent_answers }
        .to change { eligibility.teaching_subject_now }
        .from(false).to(nil)
    end

    it "resets 'has_entire_term_contract' when the value of 'employed_as_supply_teacher' changes" do
      eligibility.employed_as_supply_teacher = true
      expect { eligibility.reset_dependent_answers }.not_to change { eligibility.attributes }

      eligibility.employed_as_supply_teacher = false
      expect { eligibility.reset_dependent_answers }
        .to change { eligibility.has_entire_term_contract }
        .from(false).to(nil)
    end

    it "resets 'employed_directly' when the value of 'employed_as_supply_teacher' changes" do
      eligibility.employed_as_supply_teacher = true
      expect { eligibility.reset_dependent_answers }.not_to change { eligibility.attributes }

      eligibility.employed_as_supply_teacher = false
      expect { eligibility.reset_dependent_answers }
        .to change { eligibility.employed_directly }
        .from(false).to(nil)
    end
  end

  describe "#trainee_teacher_in_2021?" do
    context "when EarlyCareerPayments policy AcademicYear - 2021" do
      let(:eligibility) { build_stubbed(:early_career_payments_eligibility, nqt_in_academic_year_after_itt: false) }

      before do
        @ecp_policy_date = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
        PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: AcademicYear.new(2021))
      end

      after do
        PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: @ecp_policy_date)
      end

      it "returns true" do
        expect(eligibility.trainee_teacher_in_2021?).to be true
      end

      it "returns false" do
        eligibility.nqt_in_academic_year_after_itt = true
        expect(eligibility.trainee_teacher_in_2021?).to be false
      end
    end

    context "when EarlyCareerPayments policy AcademicYear - NOT 2021" do
      before do
        @ecp_policy_date = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
        PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: AcademicYear.new(2022))
      end

      after do
        PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: @ecp_policy_date)
      end

      it "returns false" do
        eligibility = EarlyCareerPayments::Eligibility.new(nqt_in_academic_year_after_itt: false)

        expect(eligibility.trainee_teacher_in_2021?).to be false
      end
    end
  end

  describe "validation contexts" do
    context "when saving in the 'nqt_in_academic_year_after_itt' context" do
      it "is not valid without a value for 'nqt_in_academic_year_after_itt'" do
        expect(EarlyCareerPayments::Eligibility.new).not_to be_valid(:"nqt-in-academic-year-after-itt")
        expect(EarlyCareerPayments::Eligibility.new(nqt_in_academic_year_after_itt: true)).to be_valid(:"nqt-in-academic-year-after-itt")
        expect(EarlyCareerPayments::Eligibility.new(nqt_in_academic_year_after_itt: false)).to be_valid(:"nqt-in-academic-year-after-itt")
      end
    end

    context "when saving in the 'employed_as_supply_teacher' context" do
      it "is not valid without a value for 'employed_as_supply_teacher'" do
        expect(EarlyCareerPayments::Eligibility.new).not_to be_valid(:"supply-teacher")
        expect(EarlyCareerPayments::Eligibility.new(employed_as_supply_teacher: true)).to be_valid(:"supply-teacher")
        expect(EarlyCareerPayments::Eligibility.new(employed_as_supply_teacher: false)).to be_valid(:"supply-teacher")
      end
    end

    context "when saving in the 'has_entire_term_contract' context" do
      it "is not valid without a value for 'has_entire_term_contract'" do
        expect(EarlyCareerPayments::Eligibility.new(employed_as_supply_teacher: true)).not_to be_valid(:"entire-term-contract")
        expect(EarlyCareerPayments::Eligibility.new(employed_as_supply_teacher: true, has_entire_term_contract: false)).to be_valid(:"entire-term-contract")
      end
    end

    context "when saving in the 'employed_directly' context" do
      it "is not valid without a value for 'employed_directly'" do
        expect(EarlyCareerPayments::Eligibility.new(employed_as_supply_teacher: true)).not_to be_valid(:"employed-directly")
        expect(EarlyCareerPayments::Eligibility.new(employed_as_supply_teacher: true, employed_directly: false)).to be_valid(:"employed-directly")
      end
    end

    context "when saving in the 'poor-peformance' context" do
      it "is not valid without a value for 'subject_to_disciplinary_action" do
        expect(EarlyCareerPayments::Eligibility.new).not_to be_valid(:"poor-performance")
      end

      it "is not valid without a value for 'subject_to_formal_performance_action'" do
        expect(EarlyCareerPayments::Eligibility.new).not_to be_valid(:"poor-performance")
      end

      it "is valid when the values are not nil" do
        expect(EarlyCareerPayments::Eligibility.new(subject_to_disciplinary_action: true, subject_to_formal_performance_action: false)).to be_valid(:"poor-performance")
        expect(EarlyCareerPayments::Eligibility.new(subject_to_disciplinary_action: false, subject_to_formal_performance_action: false)).to be_valid(:"poor-performance")
        expect(EarlyCareerPayments::Eligibility.new(subject_to_disciplinary_action: true, subject_to_formal_performance_action: true)).to be_valid(:"poor-performance")
        expect(EarlyCareerPayments::Eligibility.new(subject_to_disciplinary_action: true, subject_to_formal_performance_action: true)).to be_valid(:"poor-performance")
      end
    end

    context "when saving in the 'qualification' context" do
      it "is not valid without a value for 'qualification'" do
        expect(EarlyCareerPayments::Eligibility.new).not_to be_valid(:qualification)
      end
    end

    context "when saving in the 'eligible_itt_subject' context" do
      it "is not valid without a value for 'eligible_itt_subject'" do
        expect(EarlyCareerPayments::Eligibility.new).not_to be_valid(:"eligible-itt-subject")
      end

      it "is not valid when the value for 'eligible_itt_subject' is 'none of the above'" do
        expect(EarlyCareerPayments::Eligibility.new(eligible_itt_subject: :none_of_the_above)).to be_valid(:"eligible-itt-subject")
      end

      it "is valid when the value for 'eligible_itt_subject' is one of 'chemistry, foreign languages, mathematics or physics'" do
        expect(EarlyCareerPayments::Eligibility.new(eligible_itt_subject: :chemistry)).to be_valid(:"eligible-itt-subject")
        expect(EarlyCareerPayments::Eligibility.new(eligible_itt_subject: :physics)).to be_valid(:"eligible-itt-subject")
        expect(EarlyCareerPayments::Eligibility.new(eligible_itt_subject: :foreign_languages)).to be_valid(:"eligible-itt-subject")
      end
    end

    context "when saving in the 'teaching_subject_now' context" do
      it "is not valid without a value for 'teaching_subject_now'" do
        expect(EarlyCareerPayments::Eligibility.new).not_to be_valid(:"teaching-subject-now")
        expect(EarlyCareerPayments::Eligibility.new(teaching_subject_now: true)).to be_valid(:"teaching-subject-now")
        expect(EarlyCareerPayments::Eligibility.new(teaching_subject_now: false)).to be_valid(:"teaching-subject-now")
      end
    end

    context "when saving in the 'itt_academic_year' context" do
      it "is not valid without a value for 'itt_academic_year'" do
        expect(EarlyCareerPayments::Eligibility.new).not_to be_valid(:"itt-year")
        expect(EarlyCareerPayments::Eligibility.new(itt_academic_year: AcademicYear.new(2020))).to be_valid(:"itt-year")
      end
    end
  end
end
