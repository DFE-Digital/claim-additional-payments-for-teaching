require "rails_helper"
require "journey_subject_eligibility_checker"

RSpec.describe JourneySubjectEligibilityChecker do
  describe ".new" do
    context "claim year validation" do
      context "after LUP and ECP" do
        specify { expect { described_class.new(claim_year: AcademicYear.new(2025), itt_year: AcademicYear.new(2024)) }.to raise_error("Claim year 2025/2026 is after ECP and LUP both ended") }
      end
    end

    context "ITT year validation" do
      context "inside window" do
        specify { expect { described_class.new(claim_year: AcademicYear.new(2022), itt_year: AcademicYear.new(2017)) }.not_to raise_error }
      end

      context "outside window" do
        specify { expect { described_class.new(claim_year: AcademicYear.new(2022), itt_year: AcademicYear.new(2016)) }.to raise_error("ITT year 2016/2017 is outside the window for claim year 2022/2023") }
      end

      context "None of the above" do
        specify { expect { described_class.new(claim_year: AcademicYear.new(2022), itt_year: AcademicYear.new) }.not_to raise_error }
      end
    end
  end

  describe "#future_claim_years" do
    context "2022/2023 claim year" do
      subject { described_class.new(claim_year: AcademicYear.new(2022), itt_year: AcademicYear.new(2021)) }

      specify { expect(subject.future_claim_years).to contain_exactly(AcademicYear.new(2023), AcademicYear.new(2024)) }
    end

    context "2023/2024 claim year" do
      subject { described_class.new(claim_year: AcademicYear.new(2023), itt_year: AcademicYear.new(2022)) }

      specify { expect(subject.future_claim_years).to contain_exactly(AcademicYear.new(2024)) }
    end

    context "2024/2025 claim year" do
      subject { described_class.new(claim_year: AcademicYear.new(2024), itt_year: AcademicYear.new(2023)) }

      specify { expect(subject.future_claim_years).to be_empty }
    end

    context "None of the above ITT year" do
      subject { described_class.new(claim_year: AcademicYear.new(2022), itt_year: AcademicYear.new) }

      specify { expect(subject.future_claim_years).to be_empty }
    end
  end

  describe "#selectable_itt_years" do
    context "2022/2023 claim year" do
      subject { described_class.new(claim_year: AcademicYear.new(2022), itt_year: AcademicYear.new(2021)).selectable_itt_years }

      it { is_expected.to contain_exactly(AcademicYear.new(2017), AcademicYear.new(2018), AcademicYear.new(2019), AcademicYear.new(2020), AcademicYear.new(2021)) }
    end

    context "2023/2024 claim year" do
      subject { described_class.new(claim_year: AcademicYear.new(2023), itt_year: AcademicYear.new(2022)).selectable_itt_years }

      it { is_expected.to contain_exactly(AcademicYear.new(2018), AcademicYear.new(2019), AcademicYear.new(2020), AcademicYear.new(2021), AcademicYear.new(2022)) }
    end

    context "2024/2025 claim year" do
      subject { described_class.new(claim_year: AcademicYear.new(2024), itt_year: AcademicYear.new(2023)).selectable_itt_years }

      it { is_expected.to contain_exactly(AcademicYear.new(2019), AcademicYear.new(2020), AcademicYear.new(2021), AcademicYear.new(2022), AcademicYear.new(2023)) }
    end
  end

  describe ".selectable_itt_years_for_view" do
    context "2022/2023 claim year" do
      subject { described_class.selectable_itt_years_for_claim_year(AcademicYear.new(2022)) }

      it { is_expected.to eq([AcademicYear.new(2017), AcademicYear.new(2018), AcademicYear.new(2019), AcademicYear.new(2020), AcademicYear.new(2021)]) }
    end

    context "2023/2024 claim year" do
      subject { described_class.selectable_itt_years_for_claim_year(AcademicYear.new(2023)) }

      it { is_expected.to eq([AcademicYear.new(2018), AcademicYear.new(2019), AcademicYear.new(2020), AcademicYear.new(2021), AcademicYear.new(2022)]) }
    end

    context "2024/2025 claim year" do
      subject { described_class.selectable_itt_years_for_claim_year(AcademicYear.new(2024)) }

      it { is_expected.to eq([AcademicYear.new(2019), AcademicYear.new(2020), AcademicYear.new(2021), AcademicYear.new(2022), AcademicYear.new(2023)]) }
    end
  end

  describe "#current_subject_symbols" do
    subject { described_class.new(claim_year: claim_year, itt_year: itt_year).current_subject_symbols(policy) }

    context "ECP" do
      let(:policy) { EarlyCareerPayments }

      context "2022 claim year" do
        let(:claim_year) { AcademicYear.new(2022) }

        context "None of the above ITT year" do
          let(:itt_year) { AcademicYear.new }

          it { is_expected.to be_empty }
        end

        context "2017 ITT year" do
          let(:itt_year) { AcademicYear.new(2017) }

          it { is_expected.to be_empty }
        end

        context "2018 ITT year" do
          let(:itt_year) { AcademicYear.new(2018) }

          it { is_expected.to be_empty }
        end

        context "2019 ITT year" do
          let(:itt_year) { AcademicYear.new(2019) }

          it { is_expected.to contain_exactly(:mathematics) }
        end

        context "2020 ITT year" do
          let(:itt_year) { AcademicYear.new(2020) }

          it { is_expected.to contain_exactly(:chemistry, :foreign_languages, :mathematics, :physics) }
        end

        context "2021 ITT year" do
          let(:itt_year) { AcademicYear.new(2021) }

          it { is_expected.to be_empty }
        end
      end

      context "2023 claim year" do
        let(:claim_year) { AcademicYear.new(2023) }

        context "2018 ITT year" do
          let(:itt_year) { AcademicYear.new(2018) }

          it { is_expected.to contain_exactly(:mathematics) }
        end

        context "2019 ITT year" do
          let(:itt_year) { AcademicYear.new(2019) }

          it { is_expected.to be_empty }
        end

        context "2020 ITT year" do
          let(:itt_year) { AcademicYear.new(2020) }

          it { is_expected.to contain_exactly(:chemistry, :foreign_languages, :mathematics, :physics) }
        end

        context "2021 ITT year" do
          let(:itt_year) { AcademicYear.new(2021) }

          it { is_expected.to be_empty }
        end

        context "2022 ITT year" do
          let(:itt_year) { AcademicYear.new(2022) }

          it { is_expected.to be_empty }
        end
      end

      context "2024 claim year" do
        let(:claim_year) { AcademicYear.new(2024) }

        context "2019 ITT year" do
          let(:itt_year) { AcademicYear.new(2019) }

          it { is_expected.to contain_exactly(:mathematics) }
        end

        context "2020 ITT year" do
          let(:itt_year) { AcademicYear.new(2020) }

          it { is_expected.to contain_exactly(:chemistry, :foreign_languages, :mathematics, :physics) }
        end

        context "2021 ITT year" do
          let(:itt_year) { AcademicYear.new(2021) }

          it { is_expected.to be_empty }
        end

        context "2022 ITT year" do
          let(:itt_year) { AcademicYear.new(2022) }

          it { is_expected.to be_empty }
        end

        context "2023 ITT year" do
          let(:itt_year) { AcademicYear.new(2023) }

          it { is_expected.to be_empty }
        end
      end
    end

    context "LUP" do
      let(:policy) { LevellingUpPremiumPayments }
      let(:the_constant_lup_subjects) { [:chemistry, :computing, :mathematics, :physics] }

      context "claim year before 2022" do
        let(:claim_year) { AcademicYear.new(2021) }
        let(:itt_year) { AcademicYear.new(2017) }

        it { is_expected.to be_empty }
      end

      context "2022 claim year" do
        let(:claim_year) { AcademicYear.new(2022) }

        context "2017 itt year" do
          let(:itt_year) { AcademicYear.new(2017) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end

        context "2018 itt year" do
          let(:itt_year) { AcademicYear.new(2018) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end

        context "2019 itt year" do
          let(:itt_year) { AcademicYear.new(2019) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end

        context "2020 itt year" do
          let(:itt_year) { AcademicYear.new(2020) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end

        context "2021 itt year" do
          let(:itt_year) { AcademicYear.new(2021) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end
      end

      context "2023 claim year" do
        let(:claim_year) { AcademicYear.new(2023) }

        context "2018 itt year" do
          let(:itt_year) { AcademicYear.new(2018) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end

        context "2019 itt year" do
          let(:itt_year) { AcademicYear.new(2019) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end

        context "2020 itt year" do
          let(:itt_year) { AcademicYear.new(2020) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end

        context "2021 itt year" do
          let(:itt_year) { AcademicYear.new(2021) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end

        context "2022 itt year" do
          let(:itt_year) { AcademicYear.new(2022) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end
      end

      context "2024 claim year" do
        let(:claim_year) { AcademicYear.new(2024) }

        context "2019 itt year" do
          let(:itt_year) { AcademicYear.new(2019) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end

        context "2020 itt year" do
          let(:itt_year) { AcademicYear.new(2020) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end

        context "2021 itt year" do
          let(:itt_year) { AcademicYear.new(2021) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end

        context "2022 itt year" do
          let(:itt_year) { AcademicYear.new(2022) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end

        context "2023 itt year" do
          let(:itt_year) { AcademicYear.new(2023) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end
      end
    end

    context "unsupported policy" do
      let(:policy) { StudentLoans }

      context "2022 claim year" do
        let(:claim_year) { AcademicYear.new(2022) }

        context "2017 ITT year" do
          let(:itt_year) { AcademicYear.new(2017) }

          specify { expect { described_class.new(claim_year: claim_year, itt_year: itt_year).current_subject_symbols(policy) }.to raise_error("Unsupported policy: StudentLoans") }
        end
      end
    end
  end

  describe "#future_subject_symbols" do
    subject { described_class.new(claim_year: claim_year, itt_year: itt_year).future_subject_symbols(policy) }

    context "ECP" do
      let(:policy) { EarlyCareerPayments }

      context "2022 claim year" do
        let(:claim_year) { AcademicYear.new(2022) }

        context "None of the above ITT year" do
          let(:itt_year) { AcademicYear.new }

          it { is_expected.to be_empty }
        end

        context "2017 ITT year" do
          let(:itt_year) { AcademicYear.new(2017) }

          it { is_expected.to be_empty }
        end

        context "2018 ITT year" do
          let(:itt_year) { AcademicYear.new(2018) }

          it { is_expected.to contain_exactly(:mathematics) }
        end

        context "2019 ITT year" do
          let(:itt_year) { AcademicYear.new(2019) }

          it { is_expected.to contain_exactly(:mathematics) }
        end

        context "2020 ITT year" do
          let(:itt_year) { AcademicYear.new(2020) }

          it { is_expected.to contain_exactly(:chemistry, :foreign_languages, :mathematics, :physics) }
        end
      end

      context "2023 claim year" do
        let(:claim_year) { AcademicYear.new(2023) }

        context "2018 ITT year" do
          let(:itt_year) { AcademicYear.new(2018) }

          it { is_expected.to be_empty }
        end

        context "2019 ITT year" do
          let(:itt_year) { AcademicYear.new(2019) }

          it { is_expected.to contain_exactly(:mathematics) }
        end

        context "2020 ITT year" do
          let(:itt_year) { AcademicYear.new(2020) }

          it { is_expected.to contain_exactly(:chemistry, :foreign_languages, :mathematics, :physics) }
        end

        context "2021 ITT year" do
          let(:itt_year) { AcademicYear.new(2021) }

          it { is_expected.to be_empty }
        end

        context "2022 ITT year" do
          let(:itt_year) { AcademicYear.new(2022) }

          it { is_expected.to be_empty }
        end
      end

      context "2024 claim year" do
        let(:claim_year) { AcademicYear.new(2024) }

        context "2019 ITT year" do
          let(:itt_year) { AcademicYear.new(2019) }

          it { is_expected.to be_empty }
        end

        context "2020 ITT year" do
          let(:itt_year) { AcademicYear.new(2020) }

          it { is_expected.to be_empty }
        end

        context "2021 ITT year" do
          let(:itt_year) { AcademicYear.new(2021) }

          it { is_expected.to be_empty }
        end

        context "2022 ITT year" do
          let(:itt_year) { AcademicYear.new(2022) }

          it { is_expected.to be_empty }
        end

        context "2023 ITT year" do
          let(:itt_year) { AcademicYear.new(2023) }

          it { is_expected.to be_empty }
        end
      end
    end

    context "LUP" do
      let(:policy) { LevellingUpPremiumPayments }
      let(:the_constant_lup_subjects) { [:chemistry, :computing, :mathematics, :physics] }

      context "2022 claim year" do
        let(:claim_year) { AcademicYear.new(2022) }

        context "2017 ITT year" do
          let(:itt_year) { AcademicYear.new(2017) }

          it { is_expected.to be_empty }
        end

        context "2018 ITT year" do
          let(:itt_year) { AcademicYear.new(2018) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end

        context "2019 ITT year" do
          let(:itt_year) { AcademicYear.new(2019) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end

        context "2020 ITT year" do
          let(:itt_year) { AcademicYear.new(2020) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end

        context "2021 ITT year" do
          let(:itt_year) { AcademicYear.new(2021) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end
      end

      context "2023 claim year" do
        let(:claim_year) { AcademicYear.new(2023) }

        context "2018 ITT year" do
          let(:itt_year) { AcademicYear.new(2018) }

          it { is_expected.to be_empty }
        end

        context "2019 ITT year" do
          let(:itt_year) { AcademicYear.new(2019) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end

        context "2020 ITT year" do
          let(:itt_year) { AcademicYear.new(2020) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end

        context "2021 ITT year" do
          let(:itt_year) { AcademicYear.new(2021) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end

        context "2022 ITT year" do
          let(:itt_year) { AcademicYear.new(2022) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end
      end

      context "2024 claim year" do
        let(:claim_year) { AcademicYear.new(2024) }

        context "2019 ITT year" do
          let(:itt_year) { AcademicYear.new(2019) }

          it { is_expected.to be_empty }
        end

        context "2020 ITT year" do
          let(:itt_year) { AcademicYear.new(2020) }

          it { is_expected.to be_empty }
        end

        context "2021 ITT year" do
          let(:itt_year) { AcademicYear.new(2021) }

          it { is_expected.to be_empty }
        end

        context "2022 ITT year" do
          let(:itt_year) { AcademicYear.new(2022) }

          it { is_expected.to be_empty }
        end
      end
    end

    context "unsupported policy" do
      let(:policy) { StudentLoans }

      context "2022 claim year" do
        let(:claim_year) { AcademicYear.new(2022) }

        context "2017 ITT year" do
          let(:itt_year) { AcademicYear.new(2017) }

          specify { expect { described_class.new(claim_year: claim_year, itt_year: itt_year).future_subject_symbols(policy) }.to raise_error("Unsupported policy: StudentLoans") }
        end
      end
    end
  end

  describe "#current_and_future_subject_symbols" do
    subject { described_class.new(claim_year: claim_year, itt_year: itt_year).current_and_future_subject_symbols(policy) }

    context "ECP" do
      let(:policy) { EarlyCareerPayments }

      context "2022 claim year" do
        let(:claim_year) { AcademicYear.new(2022) }

        context "None of the above ITT year" do
          let(:itt_year) { AcademicYear.new }

          it { is_expected.to be_empty }
        end

        context "2017 ITT year" do
          let(:itt_year) { AcademicYear.new(2017) }

          it { is_expected.to be_empty }
        end

        context "2018 ITT year" do
          let(:itt_year) { AcademicYear.new(2018) }

          it { is_expected.to contain_exactly(:mathematics) }
        end

        context "2019 ITT year" do
          let(:itt_year) { AcademicYear.new(2019) }

          it { is_expected.to contain_exactly(:mathematics) }
        end

        context "2020 ITT year" do
          let(:itt_year) { AcademicYear.new(2020) }

          it { is_expected.to contain_exactly(:chemistry, :foreign_languages, :mathematics, :physics) }
        end
      end

      context "2023 claim year" do
        let(:claim_year) { AcademicYear.new(2023) }

        context "2018 ITT year" do
          let(:itt_year) { AcademicYear.new(2018) }

          it { is_expected.to contain_exactly(:mathematics) }
        end

        context "2019 ITT year" do
          let(:itt_year) { AcademicYear.new(2019) }

          it { is_expected.to contain_exactly(:mathematics) }
        end

        context "2020 ITT year" do
          let(:itt_year) { AcademicYear.new(2020) }

          it { is_expected.to contain_exactly(:chemistry, :foreign_languages, :mathematics, :physics) }
        end

        context "2021 ITT year" do
          let(:itt_year) { AcademicYear.new(2021) }

          it { is_expected.to be_empty }
        end

        context "2022 ITT year" do
          let(:itt_year) { AcademicYear.new(2022) }

          it { is_expected.to be_empty }
        end
      end

      context "2024 claim year" do
        let(:claim_year) { AcademicYear.new(2024) }

        context "2019 ITT year" do
          let(:itt_year) { AcademicYear.new(2019) }

          it { is_expected.to contain_exactly(:mathematics) }
        end

        context "2020 ITT year" do
          let(:itt_year) { AcademicYear.new(2020) }

          it { is_expected.to contain_exactly(:chemistry, :foreign_languages, :mathematics, :physics) }
        end

        context "2021 ITT year" do
          let(:itt_year) { AcademicYear.new(2021) }

          it { is_expected.to be_empty }
        end

        context "2022 ITT year" do
          let(:itt_year) { AcademicYear.new(2022) }

          it { is_expected.to be_empty }
        end

        context "2023 ITT year" do
          let(:itt_year) { AcademicYear.new(2023) }

          it { is_expected.to be_empty }
        end
      end
    end

    context "LUP" do
      let(:policy) { LevellingUpPremiumPayments }
      let(:the_constant_lup_subjects) { [:chemistry, :computing, :mathematics, :physics] }

      context "2022 claim year" do
        let(:claim_year) { AcademicYear.new(2022) }

        context "2017 ITT year" do
          let(:itt_year) { AcademicYear.new(2017) }

          it { is_expected.to contain_exactly(:chemistry, :computing, :mathematics, :physics) }
        end

        context "2018 ITT year" do
          let(:itt_year) { AcademicYear.new(2018) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end

        context "2019 ITT year" do
          let(:itt_year) { AcademicYear.new(2019) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end

        context "2020 ITT year" do
          let(:itt_year) { AcademicYear.new(2020) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end

        context "2021 ITT year" do
          let(:itt_year) { AcademicYear.new(2021) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end
      end

      context "2023 claim year" do
        let(:claim_year) { AcademicYear.new(2023) }

        context "2018 ITT year" do
          let(:itt_year) { AcademicYear.new(2018) }

          it { is_expected.to contain_exactly(:chemistry, :computing, :mathematics, :physics) }
        end

        context "2019 ITT year" do
          let(:itt_year) { AcademicYear.new(2019) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end

        context "2020 ITT year" do
          let(:itt_year) { AcademicYear.new(2020) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end

        context "2021 ITT year" do
          let(:itt_year) { AcademicYear.new(2021) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end

        context "2022 ITT year" do
          let(:itt_year) { AcademicYear.new(2022) }

          it { is_expected.to contain_exactly(*the_constant_lup_subjects) }
        end
      end

      context "2024 claim year" do
        let(:claim_year) { AcademicYear.new(2024) }

        context "2019 ITT year" do
          let(:itt_year) { AcademicYear.new(2019) }

          it { is_expected.to contain_exactly(:chemistry, :computing, :mathematics, :physics) }
        end

        context "2020 ITT year" do
          let(:itt_year) { AcademicYear.new(2020) }

          it { is_expected.to contain_exactly(:chemistry, :computing, :mathematics, :physics) }
        end

        context "2021 ITT year" do
          let(:itt_year) { AcademicYear.new(2021) }

          it { is_expected.to contain_exactly(:chemistry, :computing, :mathematics, :physics) }
        end

        context "2022 ITT year" do
          let(:itt_year) { AcademicYear.new(2022) }

          it { is_expected.to contain_exactly(:chemistry, :computing, :mathematics, :physics) }
        end
      end
    end

    context "unsupported policy" do
      let(:policy) { StudentLoans }

      context "2022 claim year" do
        let(:claim_year) { AcademicYear.new(2022) }

        context "2017 ITT year" do
          let(:itt_year) { AcademicYear.new(2017) }

          specify { expect { described_class.new(claim_year: claim_year, itt_year: itt_year).future_subject_symbols(policy) }.to raise_error("Unsupported policy: StudentLoans") }
        end
      end
    end
  end

  describe "#selectable_subject_symbols" do
    let(:eligible_ecp_eligibility) { build(:early_career_payments_eligibility, :eligible, itt_academic_year: itt_year) }
    let(:eligible_lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, itt_academic_year: itt_year) }

    let(:ineligible_ecp_eligibility) { build(:early_career_payments_eligibility, :ineligible, itt_academic_year: itt_year) }
    let(:ineligible_lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :ineligible, itt_academic_year: itt_year) }

    let(:eligible_ecp_claim) { build(:claim, :first_lup_claim_year, policy: EarlyCareerPayments, eligibility: eligible_ecp_eligibility) }
    let(:eligible_lup_claim) { build(:claim, :first_lup_claim_year, policy: LevellingUpPremiumPayments, eligibility: eligible_lup_eligibility) }

    let(:ineligible_ecp_claim) { build(:claim, :first_lup_claim_year, policy: EarlyCareerPayments, eligibility: ineligible_ecp_eligibility) }
    let(:ineligible_lup_claim) { build(:claim, :first_lup_claim_year, policy: LevellingUpPremiumPayments, eligibility: ineligible_lup_eligibility) }

    before { create(:policy_configuration, :additional_payments) }

    context "2022 claim year" do
      let(:claim_year) { AcademicYear.new(2022) }

      context "None of the above ITT year" do
        let(:itt_year) { AcademicYear.new }

        subject { described_class.new(claim_year: claim_year, itt_year: itt_year).selectable_subject_symbols(CurrentClaim.new(claims: [eligible_ecp_claim, eligible_lup_claim])) }

        it { is_expected.to be_empty }
      end

      context "2017 ITT year" do
        let(:itt_year) { AcademicYear.new(2017) }

        context "ineligible LUP" do
          subject { described_class.new(claim_year: claim_year, itt_year: itt_year).selectable_subject_symbols(CurrentClaim.new(claims: [eligible_ecp_claim, ineligible_lup_claim])) }

          it { is_expected.to be_empty }
        end

        context "eligible LUP" do
          subject { described_class.new(claim_year: claim_year, itt_year: itt_year).selectable_subject_symbols(CurrentClaim.new(claims: [eligible_ecp_claim, eligible_lup_claim])) }

          it { is_expected.to contain_exactly(:chemistry, :computing, :mathematics, :physics) }
        end
      end

      context "2018 ITT year" do
        let(:itt_year) { AcademicYear.new(2018) }

        context "ineligible LUP" do
          subject { described_class.new(claim_year: claim_year, itt_year: itt_year).selectable_subject_symbols(CurrentClaim.new(claims: [eligible_ecp_claim, ineligible_lup_claim])) }

          it { is_expected.to contain_exactly(:mathematics) }
        end

        context "eligible LUP" do
          subject { described_class.new(claim_year: claim_year, itt_year: itt_year).selectable_subject_symbols(CurrentClaim.new(claims: [eligible_ecp_claim, eligible_lup_claim])) }

          it { is_expected.to contain_exactly(:chemistry, :computing, :mathematics, :physics) }
        end
      end

      context "2019 ITT year" do
        let(:itt_year) { AcademicYear.new(2019) }

        context "ineligible LUP" do
          subject { described_class.new(claim_year: claim_year, itt_year: itt_year).selectable_subject_symbols(CurrentClaim.new(claims: [eligible_ecp_claim, ineligible_lup_claim])) }

          it { is_expected.to contain_exactly(:mathematics) }
        end

        context "eligible LUP" do
          subject { described_class.new(claim_year: claim_year, itt_year: itt_year).selectable_subject_symbols(CurrentClaim.new(claims: [eligible_ecp_claim, eligible_lup_claim])) }

          it { is_expected.to contain_exactly(:chemistry, :computing, :mathematics, :physics) }
        end
      end

      context "2020 ITT year" do
        let(:itt_year) { AcademicYear.new(2020) }

        context "ineligible LUP" do
          subject { described_class.new(claim_year: claim_year, itt_year: itt_year).selectable_subject_symbols(CurrentClaim.new(claims: [eligible_ecp_claim, ineligible_lup_claim])) }

          it { is_expected.to contain_exactly(:chemistry, :foreign_languages, :mathematics, :physics) }
        end

        context "eligible LUP" do
          subject { described_class.new(claim_year: claim_year, itt_year: itt_year).selectable_subject_symbols(CurrentClaim.new(claims: [eligible_ecp_claim, eligible_lup_claim])) }

          it { is_expected.to contain_exactly(:chemistry, :computing, :foreign_languages, :mathematics, :physics) }
        end
      end

      context "2021 ITT year" do
        let(:itt_year) { AcademicYear.new(2021) }

        context "ineligible LUP" do
          subject { described_class.new(claim_year: claim_year, itt_year: itt_year).selectable_subject_symbols(CurrentClaim.new(claims: [eligible_ecp_claim, ineligible_lup_claim])) }

          it { is_expected.to be_empty }
        end

        context "eligible LUP" do
          subject { described_class.new(claim_year: claim_year, itt_year: itt_year).selectable_subject_symbols(CurrentClaim.new(claims: [eligible_ecp_claim, eligible_lup_claim])) }

          it { is_expected.to contain_exactly(:chemistry, :computing, :mathematics, :physics) }
        end
      end
    end
  end

  describe "#next_eligible_claim_year_after_current_claim_year" do
    before { create(:policy_configuration, :additional_payments) }

    context "2022 claim year" do
      let(:claim_year) { AcademicYear.new(2022) }

      context "None of the above ITT year" do
        let(:itt_year) { AcademicYear.new }

        let(:ineligible_ecp_eligibility) { build(:early_career_payments_eligibility, :ineligible, eligible_itt_subject: :mathematics, itt_academic_year: itt_year) }
        let(:ineligible_lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :ineligible, eligible_itt_subject: :mathematics, itt_academic_year: itt_year) }

        let(:ineligible_ecp_claim) { build(:claim, :first_lup_claim_year, policy: EarlyCareerPayments, eligibility: ineligible_ecp_eligibility) }
        let(:ineligible_lup_claim) { build(:claim, :first_lup_claim_year, policy: LevellingUpPremiumPayments, eligibility: ineligible_lup_eligibility) }

        subject { described_class.new(claim_year: claim_year, itt_year: itt_year).next_eligible_claim_year_after_current_claim_year(CurrentClaim.new(claims: [ineligible_ecp_claim, ineligible_lup_claim])) }

        it { is_expected.to be_nil }
      end

      context "2018 ITT year" do
        let(:itt_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2018)) }

        let(:ineligible_ecp_eligibility) { build(:early_career_payments_eligibility, :ineligible, eligible_itt_subject: :mathematics, itt_academic_year: itt_year) }
        let(:ineligible_lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :ineligible, eligible_itt_subject: :mathematics, itt_academic_year: itt_year) }

        let(:ineligible_ecp_claim) { build(:claim, :first_lup_claim_year, policy: EarlyCareerPayments, eligibility: ineligible_ecp_eligibility) }
        let(:ineligible_lup_claim) { build(:claim, :first_lup_claim_year, policy: LevellingUpPremiumPayments, eligibility: ineligible_lup_eligibility) }

        subject { described_class.new(claim_year: claim_year, itt_year: itt_year).next_eligible_claim_year_after_current_claim_year(CurrentClaim.new(claims: [ineligible_ecp_claim, ineligible_lup_claim])) }

        it { is_expected.to eq(AcademicYear.new(2023)) }
      end
    end

    context "2024 claim year (final policy year)" do
      let(:claim_year) { AcademicYear.new(2024) }

      context "2019 ITT year" do
        let(:itt_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2019)) }

        let(:ineligible_ecp_eligibility) { build(:early_career_payments_eligibility, :ineligible, eligible_itt_subject: :mathematics, itt_academic_year: itt_year) }
        let(:ineligible_lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :ineligible, eligible_itt_subject: :mathematics, itt_academic_year: itt_year) }

        let(:ineligible_ecp_claim) { build(:claim, :first_lup_claim_year, policy: EarlyCareerPayments, eligibility: ineligible_ecp_eligibility) }
        let(:ineligible_lup_claim) { build(:claim, :first_lup_claim_year, policy: LevellingUpPremiumPayments, eligibility: ineligible_lup_eligibility) }

        subject { described_class.new(claim_year: claim_year, itt_year: itt_year).next_eligible_claim_year_after_current_claim_year(CurrentClaim.new(claims: [ineligible_ecp_claim, ineligible_lup_claim])) }

        it { is_expected.to be_nil }
      end
    end
  end

  describe ".first_eligible_itt_year_for_subject" do
    subject { described_class.first_eligible_itt_year_for_subject(policy: policy, claim_year: claim_year, subject_symbol: subject_symbol) }

    context "string instead of symbol" do
      specify { expect { described_class.first_eligible_itt_year_for_subject(policy: EarlyCareerPayments, claim_year: AcademicYear.new(2022), subject_symbol: "mathematics") }.to raise_error "[mathematics] is not a symbol" }
    end

    context "ECP" do
      let(:policy) { EarlyCareerPayments }

      context "2022 claim year" do
        let(:claim_year) { AcademicYear.new(2022) }

        context "mathematics" do
          let(:subject_symbol) { :mathematics }

          it { is_expected.to eq(AcademicYear.new(2019)) }
        end

        context "physics" do
          let(:subject_symbol) { :physics }

          it { is_expected.to eq(AcademicYear.new(2020)) }
        end

        context "chemistry" do
          let(:subject_symbol) { :chemistry }

          it { is_expected.to eq(AcademicYear.new(2020)) }
        end

        context "computing" do
          let(:subject_symbol) { :computing }

          it { is_expected.to be_nil }
        end

        context "languages" do
          let(:subject_symbol) { :foreign_languages }

          it { is_expected.to eq(AcademicYear.new(2020)) }
        end
      end

      context "2023 claim year" do
        let(:claim_year) { AcademicYear.new(2023) }

        context "mathematics" do
          let(:subject_symbol) { :mathematics }

          it { is_expected.to eq(AcademicYear.new(2018)) }
        end

        context "physics" do
          let(:subject_symbol) { :physics }

          it { is_expected.to eq(AcademicYear.new(2020)) }
        end

        context "chemistry" do
          let(:subject_symbol) { :chemistry }

          it { is_expected.to eq(AcademicYear.new(2020)) }
        end

        context "computing" do
          let(:subject_symbol) { :computing }

          it { is_expected.to be_nil }
        end

        context "languages" do
          let(:subject_symbol) { :foreign_languages }

          it { is_expected.to eq(AcademicYear.new(2020)) }
        end
      end

      context "2024 claim year" do
        let(:claim_year) { AcademicYear.new(2024) }

        context "mathematics" do
          let(:subject_symbol) { :mathematics }

          it { is_expected.to eq(AcademicYear.new(2019)) }
        end

        context "physics" do
          let(:subject_symbol) { :physics }

          it { is_expected.to eq(AcademicYear.new(2020)) }
        end

        context "chemistry" do
          let(:subject_symbol) { :chemistry }

          it { is_expected.to eq(AcademicYear.new(2020)) }
        end

        context "computing" do
          let(:subject_symbol) { :computing }

          it { is_expected.to be_nil }
        end

        context "languages" do
          let(:subject_symbol) { :foreign_languages }

          it { is_expected.to eq(AcademicYear.new(2020)) }
        end
      end
    end

    context "LUP" do
      let(:policy) { LevellingUpPremiumPayments }

      context "2022 claim year" do
        let(:claim_year) { AcademicYear.new(2022) }

        context "mathematics" do
          let(:subject_symbol) { :mathematics }

          it { is_expected.to eq(AcademicYear.new(2017)) }
        end

        context "physics" do
          let(:subject_symbol) { :physics }

          it { is_expected.to eq(AcademicYear.new(2017)) }
        end

        context "chemistry" do
          let(:subject_symbol) { :chemistry }

          it { is_expected.to eq(AcademicYear.new(2017)) }
        end

        context "languages" do
          let(:subject_symbol) { :foreign_languages }

          it { is_expected.to be_nil }
        end
      end

      context "2023 claim year" do
        let(:claim_year) { AcademicYear.new(2023) }

        context "mathematics" do
          let(:subject_symbol) { :mathematics }

          it { is_expected.to eq(AcademicYear.new(2018)) }
        end

        context "physics" do
          let(:subject_symbol) { :physics }

          it { is_expected.to eq(AcademicYear.new(2018)) }
        end

        context "chemistry" do
          let(:subject_symbol) { :chemistry }

          it { is_expected.to eq(AcademicYear.new(2018)) }
        end

        context "languages" do
          let(:subject_symbol) { :foreign_languages }

          it { is_expected.to be_nil }
        end
      end

      context "2024 claim year" do
        let(:claim_year) { AcademicYear.new(2024) }

        context "mathematics" do
          let(:subject_symbol) { :mathematics }

          it { is_expected.to eq(AcademicYear.new(2019)) }
        end

        context "physics" do
          let(:subject_symbol) { :physics }

          it { is_expected.to eq(AcademicYear.new(2019)) }
        end

        context "chemistry" do
          let(:subject_symbol) { :chemistry }

          it { is_expected.to eq(AcademicYear.new(2019)) }
        end

        context "languages" do
          let(:subject_symbol) { :foreign_languages }

          it { is_expected.to be_nil }
        end
      end
    end
  end

  describe ".fixed_lup_subject_symbols" do
    specify { expect(described_class.fixed_lup_subject_symbols).to contain_exactly(:chemistry, :computing, :mathematics, :physics) }
  end
end
