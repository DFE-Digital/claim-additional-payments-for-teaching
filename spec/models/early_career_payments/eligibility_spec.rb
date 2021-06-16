# frozen_string_literal: true

require "rails_helper"

RSpec.describe EarlyCareerPayments::Eligibility, type: :model do
  describe "#policy" do
    let(:early_career_payments_eligibility) { build(:early_career_payments_eligibility) }

    it "has a policy class of 'EarlyCareerPayments'" do
      expect(early_career_payments_eligibility.policy).to eq EarlyCareerPayments
    end
  end

  describe "pgitt_or_ugitt_course attribute" do
    it "rejects invalid values" do
      expect { EarlyCareerPayments::Eligibility.new(pgitt_or_ugitt_course: "non-existance") }.to raise_error(ArgumentError)
    end

    it "has handily named boolean methods for the possible values" do
      eligibility = EarlyCareerPayments::Eligibility.new(pgitt_or_ugitt_course: "postgraduate")

      expect(eligibility.postgraduate_itt_course?).to eq true
      expect(eligibility.undergraduate_itt_course?).to eq false
    end
  end

  describe "eligible_itt_subject" do
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
    context "when claim is eligible later" do
      let(:eligibility_args) do
        {
          eligible_itt_subject: itt_subject,
          itt_academic_year: itt_academic_year
        }
      end

      [
        {itt_subject: "Mathematics", itt_academic_year: "2019 - 2020"},
        {itt_subject: "Mathematics", itt_academic_year: "2020 - 2021"},
        {itt_subject: "Physics", itt_academic_year: "2020 - 2021"},
        {itt_subject: "Chemistry", itt_academic_year: "2020 - 2021"},
        {itt_subject: "Foreign languages", itt_academic_year: "2020 - 2021"}
      ].each do |context|
        context "with ITT subject #{context[:itt_subject]}" do
          let(:itt_subject) { context[:itt_subject].gsub(/\s/, "_").downcase }

          context "with ITT academic year #{context[:itt_academic_year]}" do
            let(:itt_academic_year) { context[:itt_academic_year].gsub(/\s-\s/, "_") }

            it "returns true" do
              expect(EarlyCareerPayments::Eligibility.new(eligibility_args).eligible_later?).to eql true
            end
          end
        end
      end
    end

    context "when claim is not eligible later" do
      let(:eligibility_args) do
        {
          eligible_itt_subject: :mathematics,
          itt_academic_year: "2018_2019"
        }
      end

      it "returns false" do
        expect(EarlyCareerPayments::Eligibility.new(eligibility_args).eligible_later?).to eql false
      end
    end
  end

  describe "itt_academic_year" do
    it "rejects invalid values" do
      expect { EarlyCareerPayments::Eligibility.new(itt_academic_year: "2025_2026") }.to raise_error(ArgumentError)
    end

    it "has handily named boolean methods for the possible values" do
      eligibility = EarlyCareerPayments::Eligibility.new(itt_academic_year: "2018_2019")

      expect(eligibility.itt_academic_year_2018_2019?).to eq true
      expect(eligibility.itt_academic_year_2019_2020?).to eq false
      expect(eligibility.itt_academic_year_2020_2021?).to eq false
    end
  end

  describe "#ineligible?" do
    it "returns false when the eligibility cannot be determined" do
      expect(EarlyCareerPayments::Eligibility.new.ineligible?).to eql false
    end

    it "returns true when the NQT acdemic year was not the year after the ITT" do
      expect(EarlyCareerPayments::Eligibility.new(nqt_in_academic_year_after_itt: false).ineligible?).to eql true
      expect(EarlyCareerPayments::Eligibility.new(nqt_in_academic_year_after_itt: true).ineligible?).to eql false
    end

    it "returns true when claimant is a supply teacher without a contract of at least one term" do
      expect(EarlyCareerPayments::Eligibility.new(employed_as_supply_teacher: true, has_entire_term_contract: false).ineligible?).to eql true
      expect(EarlyCareerPayments::Eligibility.new(employed_as_supply_teacher: true, has_entire_term_contract: true).ineligible?).to eql false
    end

    it "returns true when claimant is a supply teacher employed by a private agency" do
      expect(EarlyCareerPayments::Eligibility.new(employed_as_supply_teacher: true, employed_directly: false).ineligible?).to eql true
      expect(EarlyCareerPayments::Eligibility.new(employed_as_supply_teacher: true, employed_directly: true).ineligible?).to eql false
    end

    it "returns true when subject to formal performance action" do
      expect(EarlyCareerPayments::Eligibility.new(subject_to_formal_performance_action: true).ineligible?).to eql true
      expect(EarlyCareerPayments::Eligibility.new(subject_to_formal_performance_action: false).ineligible?).to eql false
    end

    it "returns true when subject to disciplinary action" do
      expect(EarlyCareerPayments::Eligibility.new(subject_to_disciplinary_action: true).ineligible?).to eql true
      expect(EarlyCareerPayments::Eligibility.new(subject_to_disciplinary_action: false).ineligible?).to eql false
    end

    it "returns true when none of the eligible ITT courses were taken" do
      expect(EarlyCareerPayments::Eligibility.new(eligible_itt_subject: :none_of_the_above).ineligible?).to eql true
      expect(EarlyCareerPayments::Eligibility.new(eligible_itt_subject: :mathematics).ineligible?).to eql false
    end

    it "returns true when still teaching now the course indentified as being eligible ITT subject" do
      expect(EarlyCareerPayments::Eligibility.new(teaching_subject_now: false).ineligible?).to eql true
      expect(EarlyCareerPayments::Eligibility.new(teaching_subject_now: true).ineligible?).to eql false
    end

    it "returns true when the ITT postgraduate start date OR ITT undergraduate complete date not in 2018 - 2019, 2019 - 2020, 2020 - 2021" do
      expect(EarlyCareerPayments::Eligibility.new(itt_academic_year: :none_of_the_above).ineligible?).to eql true
      expect(EarlyCareerPayments::Eligibility.new(itt_academic_year: "2018_2019").ineligible?).to eql false
      expect(EarlyCareerPayments::Eligibility.new(itt_academic_year: "2019_2020").ineligible?).to eql false
      expect(EarlyCareerPayments::Eligibility.new(itt_academic_year: "2020_2021").ineligible?).to eql false
    end

    context "when cohort is eligible" do
      let(:eligibility_args) do
        {
          eligible_itt_subject: itt_subject,
          itt_academic_year: itt_academic_year
        }
      end

      [
        {itt_subject: "Mathematics", itt_academic_year: "2018 - 2019"},
        {itt_subject: "Mathematics", itt_academic_year: "2019 - 2020"},
        {itt_subject: "Mathematics", itt_academic_year: "2020 - 2021"},
        {itt_subject: "Physics", itt_academic_year: "2020 - 2021"},
        {itt_subject: "Chemistry", itt_academic_year: "2020 - 2021"},
        {itt_subject: "Foreign languages", itt_academic_year: "2020 - 2021"}
      ].each do |context|
        context "with ITT subject #{context[:itt_subject]}" do
          let(:itt_subject) { context[:itt_subject].gsub(/\s/, "_").downcase }

          context "with ITT academic year #{context[:itt_academic_year]}" do
            let(:itt_academic_year) { context[:itt_academic_year].gsub(/\s-\s/, "_") }

            it "returns false" do
              expect(EarlyCareerPayments::Eligibility.new(eligibility_args).ineligible?).to eql false
            end
          end
        end
      end
    end
  end

  describe "#ineligibility_reason" do
    it "returns nil when the reason for ineligibility cannot be determined" do
      expect(EarlyCareerPayments::Eligibility.new.ineligibility_reason).to be_nil
    end

    it "returns a symbol indicating the reason for ineligibility" do
      expect(EarlyCareerPayments::Eligibility.new(nqt_in_academic_year_after_itt: false).ineligibility_reason).to eq :ineligible_nqt_in_academic_year_after_itt
      expect(EarlyCareerPayments::Eligibility.new(employed_as_supply_teacher: true, has_entire_term_contract: false).ineligibility_reason).to eql :generic_ineligibility
      expect(EarlyCareerPayments::Eligibility.new(employed_as_supply_teacher: true, employed_directly: false).ineligibility_reason).to eql :generic_ineligibility
      expect(EarlyCareerPayments::Eligibility.new(subject_to_formal_performance_action: true).ineligibility_reason).to eq :subject_to_formal_performance_action
      expect(EarlyCareerPayments::Eligibility.new(subject_to_disciplinary_action: true).ineligibility_reason).to eql :generic_ineligibility
      expect(EarlyCareerPayments::Eligibility.new(eligible_itt_subject: :none_of_the_above).ineligibility_reason).to eq :itt_subject_none_of_the_above
      expect(EarlyCareerPayments::Eligibility.new(teaching_subject_now: false).ineligibility_reason).to eql :not_teaching_now_in_eligible_itt_subject
      expect(EarlyCareerPayments::Eligibility.new(itt_academic_year: :none_of_the_above).ineligibility_reason).to eql :generic_ineligibility
    end
  end

  describe "#award_amount" do
    context "when cohort is eligible" do
      let(:eligibility_args) do
        {
          eligible_itt_subject: itt_subject,
          itt_academic_year: itt_academic_year
        }
      end

      [
        {
          context: {
            itt_subject: "Mathematics",
            itt_academic_year: "2018 - 2019"
          },
          expect: {
            base_amount: 5_000,
            uplift_amount: 7_500
          }
        },
        {
          context: {
            itt_subject: "Mathematics",
            itt_academic_year: "2019 - 2020"
          },
          expect: {
            base_amount: 5_000,
            uplift_amount: 7_500
          }
        },
        {
          context: {
            itt_subject: "Mathematics",
            itt_academic_year: "2020 - 2021"
          },
          expect: {
            base_amount: 2_000,
            uplift_amount: 3_000
          }
        },
        {
          context: {
            itt_subject: "Physics",
            itt_academic_year: "2020 - 2021"
          },
          expect: {
            base_amount: 2_000,
            uplift_amount: 3_000
          }
        },
        {
          context: {
            itt_subject: "Chemistry",
            itt_academic_year: "2020 - 2021"
          },
          expect: {
            base_amount: 2_000,
            uplift_amount: 3_000
          }
        },
        {
          context: {
            itt_subject: "Foreign languages",
            itt_academic_year: "2020 - 2021"
          },
          expect: {
            base_amount: 2_000,
            uplift_amount: 3_000
          }
        }
      ].each do |spec|
        context "with ITT subject #{spec[:context][:itt_subject]}" do
          let(:itt_subject) { spec[:context][:itt_subject].gsub(/\s/, "_").downcase }

          context "with ITT academic year #{spec[:context][:itt_academic_year]}" do
            let(:itt_academic_year) { spec[:context][:itt_academic_year].gsub(/\s-\s/, "_") }

            it "returns hash with correct values" do
              expect(EarlyCareerPayments::Eligibility.new(eligibility_args).award_amount).to eq(spec[:expect][:base_amount])
            end
          end
        end
      end
    end
  end

  describe "#award_amounts" do
    context "when cohort is eligible" do
      let(:eligibility_args) do
        {
          eligible_itt_subject: itt_subject,
          itt_academic_year: itt_academic_year
        }
      end

      [
        {
          context: {
            itt_subject: "Mathematics",
            itt_academic_year: "2018 - 2019"
          },
          expect: {
            base_amount: 5_000,
            uplift_amount: 7_500
          }
        },
        {
          context: {
            itt_subject: "Mathematics",
            itt_academic_year: "2019 - 2020"
          },
          expect: {
            base_amount: 5_000,
            uplift_amount: 7_500
          }
        },
        {
          context: {
            itt_subject: "Mathematics",
            itt_academic_year: "2020 - 2021"
          },
          expect: {
            base_amount: 2_000,
            uplift_amount: 3_000
          }
        },
        {
          context: {
            itt_subject: "Physics",
            itt_academic_year: "2020 - 2021"
          },
          expect: {
            base_amount: 2_000,
            uplift_amount: 3_000
          }
        },
        {
          context: {
            itt_subject: "Chemistry",
            itt_academic_year: "2020 - 2021"
          },
          expect: {
            base_amount: 2_000,
            uplift_amount: 3_000
          }
        },
        {
          context: {
            itt_subject: "Foreign languages",
            itt_academic_year: "2020 - 2021"
          },
          expect: {
            base_amount: 2_000,
            uplift_amount: 3_000
          }
        }
      ].each do |spec|
        context "with ITT subject #{spec[:context][:itt_subject]}" do
          let(:itt_subject) { spec[:context][:itt_subject].gsub(/\s/, "_").downcase }

          context "with ITT academic year #{spec[:context][:itt_academic_year]}" do
            let(:itt_academic_year) { spec[:context][:itt_academic_year].gsub(/\s-\s/, "_") }

            it "returns hash with correct values" do
              expect(EarlyCareerPayments::Eligibility.new(eligibility_args).award_amounts).to eq(
                {
                  base: spec[:expect][:base_amount],
                  uplift: spec[:expect][:uplift_amount]
                }
              )
            end
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
        pgitt_or_ugitt_course: :undergraduate,
        eligible_itt_subject: :none_of_the_above,
        teaching_subject_now: false
      )
    end

    it "resets 'eligible_itt_subject' when value of 'pgitt_or_ugitt_course' changes" do
      eligibility.pgitt_or_ugitt_course = :undergraduate
      expect { eligibility.reset_dependent_answers }.not_to change { eligibility.attributes }

      eligibility.pgitt_or_ugitt_course = :postgraduate
      expect { eligibility.reset_dependent_answers }
        .to change { eligibility.eligible_itt_subject }
        .from("none_of_the_above").to(nil)
    end

    it "resets 'teaching_subject_now' when value of 'pgitt_or_ugitt_course' changes" do
      eligibility.pgitt_or_ugitt_course = :undergraduate
      expect { eligibility.reset_dependent_answers }.not_to change { eligibility.attributes }

      eligibility.pgitt_or_ugitt_course = :postgraduate
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

    it "resets 'postgraduate_masters_loan' when the value of 'claim.has_student_loan' changes from true to false" do
      expect { eligibility.reset_dependent_answers }.not_to change { eligibility.attributes }

      claim.has_student_loan = false
      expect { eligibility.reset_dependent_answers }
        .to change { eligibility.postgraduate_masters_loan }
        .from(true).to(nil)
    end

    it "resets 'postgraduate_doctoral_loan' when the value of 'claim.has_student_loan' changes from true to false" do
      expect { eligibility.reset_dependent_answers }.not_to change { eligibility.attributes }

      claim.has_student_loan = false
      expect { eligibility.reset_dependent_answers }
        .to change { eligibility.postgraduate_doctoral_loan }
        .from(true).to(nil)
    end
  end

  describe "validation contexts" do
    context "when saving in the 'subject_to_disciplinary_action' context" do
      it "is not valid without a value for 'subject_to_disciplinary_action" do
        expect(EarlyCareerPayments::Eligibility.new).not_to be_valid(:"disciplinary-action")
      end
    end

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

    context "when saving in the 'subject_to_formal_performance_action' context" do
      it "is not valid without a value for 'subject_to_formal_performance_action'" do
        expect(EarlyCareerPayments::Eligibility.new).not_to be_valid(:"formal-performance-action")
        expect(EarlyCareerPayments::Eligibility.new(subject_to_formal_performance_action: true)).to be_valid(:"formal-performance-action")
        expect(EarlyCareerPayments::Eligibility.new(subject_to_formal_performance_action: false)).to be_valid(:"formal-performance-action")
      end
    end

    context "when saving in the 'pgitt_or_ugitt_course' context" do
      it "is not valid without a value for 'pgitt_or_ugitt_course'" do
        expect(EarlyCareerPayments::Eligibility.new).not_to be_valid(:"postgraduate-itt-or-undergraduate-itt-course")
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
        expect(EarlyCareerPayments::Eligibility.new(itt_academic_year: "2020_2021")).to be_valid(:"itt-year")
      end
    end

    describe "when saving in the 'postgraduate_masters_loan' context" do
      let!(:claim) { build_stubbed(:claim, :with_student_loan, eligibility: eligibility) }
      let(:eligibility) do
        build_stubbed(
          :early_career_payments_eligibility,
          :eligible,
          employed_as_supply_teacher: true,
          has_entire_term_contract: false,
          employed_directly: false,
          pgitt_or_ugitt_course: :undergraduate,
          eligible_itt_subject: :none_of_the_above,
          teaching_subject_now: false,
          postgraduate_masters_loan: nil
        )
      end

      context "with claim having a student loan" do
        it "is not valid without a value for 'postgraduate_masters_loan'" do
          expect(eligibility).not_to be_valid(:"masters-loan")

          eligibility.postgraduate_masters_loan = true
          expect(eligibility).to be_valid(:"masters-loan")

          eligibility.postgraduate_masters_loan = false
          expect(eligibility).to be_valid(:"masters-loan")
        end
      end

      context "with claim having no_student_loan" do
        it "is valid without a value for 'postgraduate_masters_loan'" do
          subject.validate(on: :"masters-loan")
          expect(subject.errors[:"masters-loan"]).to be_empty
        end
      end
    end

    describe "when saving in the 'postgraduate_doctoral_loan' context" do
      let!(:claim) { build_stubbed(:claim, :with_student_loan, eligibility: eligibility) }
      let(:eligibility) do
        build_stubbed(
          :early_career_payments_eligibility,
          :eligible,
          employed_as_supply_teacher: true,
          has_entire_term_contract: false,
          employed_directly: false,
          pgitt_or_ugitt_course: :undergraduate,
          eligible_itt_subject: :none_of_the_above,
          teaching_subject_now: false,
          postgraduate_doctoral_loan: nil
        )
      end

      context "with claim having a student loan" do
        it "is not valid without a value for 'postgraduate_doctoral_loan'" do
          expect(eligibility).not_to be_valid(:"doctoral-loan")

          eligibility.postgraduate_doctoral_loan = true
          expect(eligibility).to be_valid(:"doctoral-loan")

          eligibility.postgraduate_doctoral_loan = false
          expect(eligibility).to be_valid(:"doctoral-loan")
        end
      end

      context "with claim having no_student_loan" do
        it "is valid without a value for 'postgraduate_doctoral_loan'" do
          subject.validate(on: :"doctoral-loan")
          expect(subject.errors[:"doctoral-loan"]).to be_empty
        end
      end
    end
  end
end
