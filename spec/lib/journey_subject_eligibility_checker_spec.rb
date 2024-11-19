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

  describe "#current_subject_symbols" do
    subject { described_class.new(claim_year: claim_year, itt_year: itt_year).current_subject_symbols(policy) }

    context "ECP" do
      let(:policy) { Policies::EarlyCareerPayments }

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
      let(:policy) { Policies::LevellingUpPremiumPayments }
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
      let(:policy) { Policies::StudentLoans }

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
      let(:policy) { Policies::EarlyCareerPayments }

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
      let(:policy) { Policies::LevellingUpPremiumPayments }
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
      let(:policy) { Policies::StudentLoans }

      context "2022 claim year" do
        let(:claim_year) { AcademicYear.new(2022) }

        context "2017 ITT year" do
          let(:itt_year) { AcademicYear.new(2017) }

          specify { expect { described_class.new(claim_year: claim_year, itt_year: itt_year).future_subject_symbols(policy) }.to raise_error("Unsupported policy: StudentLoans") }
        end
      end
    end
  end
end
