require "rails_helper"

describe Policies::EarlyCareerPayments::AwardAmountCalculator do
  let(:base_school) { instance_double("School", eligible_for_early_career_payments?: true, eligible_for_early_career_payments_as_uplift?: false) }
  let(:uplift_school) { instance_double("School", eligible_for_early_career_payments?: true, eligible_for_early_career_payments_as_uplift?: true) }
  let(:ineligible_school) { instance_double("School", eligible_for_early_career_payments?: false) }

  describe ".new" do
    context "with string instead of symbol" do
      specify { expect { described_class.new(policy_year: AcademicYear.new(2021), itt_year: AcademicYear.new(2018), subject_symbol: "mathematics", school: base_school) }.to raise_error("[\"mathematics\"] is not a symbol") }
    end

    context "nil policy year" do
      specify { expect { described_class.new(policy_year: nil, itt_year: AcademicYear.new(2019), subject_symbol: :mathematics, school: base_school) }.to raise_error("nil policy year") }
    end

    context "nil ITT year" do
      specify { expect { described_class.new(policy_year: AcademicYear.new(2022), itt_year: nil, subject_symbol: :mathematics, school: base_school) }.to raise_error("nil ITT year") }
    end

    context "nil subject" do
      specify { expect { described_class.new(policy_year: AcademicYear.new(2022), itt_year: AcademicYear.new(2019), subject_symbol: nil, school: base_school) }.to raise_error("[nil] is not a symbol") }
    end

    context "nil school" do
      specify { expect { described_class.new(policy_year: AcademicYear.new(2022), itt_year: AcademicYear.new(2019), subject_symbol: :mathematics, school: nil) }.to raise_error("nil school") }
    end
  end

  describe "#amount_in_pounds" do
    let(:calculator) { described_class.new(policy_year: policy_year, itt_year: itt_year, subject_symbol: subject_symbol, school: school) }
    subject { calculator.amount_in_pounds }

    context "2021 policy year" do
      let(:policy_year) { AcademicYear.new(2021) }

      context "2018 ITT year" do
        let(:itt_year) { AcademicYear.new(2018) }

        context "mathematics" do
          let(:subject_symbol) { :mathematics }

          context "base" do
            let(:school) { base_school }

            it { is_expected.to eq(5_000) }
          end

          context "uplift" do
            let(:school) { uplift_school }

            it { is_expected.to eq(7_500) }
          end

          context "ineligible" do
            let(:school) { ineligible_school }

            it { is_expected.to be_zero }
          end
        end

        context "physics" do
          let(:subject_symbol) { :physics }

          context "base" do
            let(:school) { base_school }

            it { is_expected.to be_zero }
          end
        end
      end
    end

    context "2022 policy year" do
      let(:policy_year) { AcademicYear.new(2022) }

      context "2019 ITT year" do
        let(:itt_year) { AcademicYear.new(2019) }

        context "mathematics" do
          let(:subject_symbol) { :mathematics }

          context "base" do
            let(:school) { base_school }

            it { is_expected.to eq(5_000) }
          end

          context "uplift" do
            let(:school) { uplift_school }

            it { is_expected.to eq(7_500) }
          end
        end
      end

      context "2020 ITT year" do
        let(:itt_year) { AcademicYear.new(2020) }

        context "mathematics" do
          let(:subject_symbol) { :mathematics }

          context "base" do
            let(:school) { base_school }

            it { is_expected.to eq(2_000) }
          end

          context "uplift" do
            let(:school) { uplift_school }

            it { is_expected.to eq(3_000) }
          end
        end

        context "physics" do
          let(:subject_symbol) { :physics }

          context "base" do
            let(:school) { base_school }

            it { is_expected.to eq(2_000) }
          end

          context "uplift" do
            let(:school) { uplift_school }

            it { is_expected.to eq(3_000) }
          end
        end

        context "chemistry" do
          let(:subject_symbol) { :chemistry }

          context "base" do
            let(:school) { base_school }

            it { is_expected.to eq(2_000) }
          end

          context "uplift" do
            let(:school) { uplift_school }

            it { is_expected.to eq(3_000) }
          end
        end

        context "languages" do
          let(:subject_symbol) { :foreign_languages }

          context "base" do
            let(:school) { base_school }

            it { is_expected.to eq(2_000) }
          end

          context "uplift" do
            let(:school) { uplift_school }

            it { is_expected.to eq(3_000) }
          end
        end
      end
    end

    context "2023 policy year" do
      let(:policy_year) { AcademicYear.new(2023) }

      context "2018 ITT year" do
        let(:itt_year) { AcademicYear.new(2018) }

        context "mathematics" do
          let(:subject_symbol) { :mathematics }

          context "base" do
            let(:school) { base_school }

            it { is_expected.to eq(5_000) }
          end

          context "uplift" do
            let(:school) { uplift_school }

            it { is_expected.to eq(7_500) }
          end
        end
      end

      context "2020 ITT year" do
        let(:itt_year) { AcademicYear.new(2020) }

        context "mathematics" do
          let(:subject_symbol) { :mathematics }

          context "base" do
            let(:school) { base_school }

            it { is_expected.to eq(2_000) }
          end

          context "uplift" do
            let(:school) { uplift_school }

            it { is_expected.to eq(3_000) }
          end
        end

        context "physics" do
          let(:subject_symbol) { :physics }

          context "base" do
            let(:school) { base_school }

            it { is_expected.to eq(2_000) }
          end

          context "uplift" do
            let(:school) { uplift_school }

            it { is_expected.to eq(3_000) }
          end
        end

        context "chemistry" do
          let(:subject_symbol) { :chemistry }

          context "base" do
            let(:school) { base_school }

            it { is_expected.to eq(2_000) }
          end

          context "uplift" do
            let(:school) { uplift_school }

            it { is_expected.to eq(3_000) }
          end
        end

        context "languages" do
          let(:subject_symbol) { :foreign_languages }

          context "base" do
            let(:school) { base_school }

            it { is_expected.to eq(2_000) }
          end

          context "uplift" do
            let(:school) { uplift_school }

            it { is_expected.to eq(3_000) }
          end
        end
      end
    end

    context "2024 policy year" do
      let(:policy_year) { AcademicYear.new(2024) }

      context "2019 ITT year" do
        let(:itt_year) { AcademicYear.new(2019) }

        context "mathematics" do
          let(:subject_symbol) { :mathematics }

          context "base" do
            let(:school) { base_school }

            it { is_expected.to eq(5_000) }
          end

          context "uplift" do
            let(:school) { uplift_school }

            it { is_expected.to eq(7_500) }
          end
        end
      end

      context "2020 ITT year" do
        let(:itt_year) { AcademicYear.new(2020) }

        context "mathematics" do
          let(:subject_symbol) { :mathematics }

          context "base" do
            let(:school) { base_school }

            it { is_expected.to eq(2_000) }
          end

          context "uplift" do
            let(:school) { uplift_school }

            it { is_expected.to eq(3_000) }
          end
        end

        context "physics" do
          let(:subject_symbol) { :physics }

          context "base" do
            let(:school) { base_school }

            it { is_expected.to eq(2_000) }
          end

          context "uplift" do
            let(:school) { uplift_school }

            it { is_expected.to eq(3_000) }
          end
        end

        context "chemistry" do
          let(:subject_symbol) { :chemistry }

          context "base" do
            let(:school) { base_school }

            it { is_expected.to eq(2_000) }
          end

          context "uplift" do
            let(:school) { uplift_school }

            it { is_expected.to eq(3_000) }
          end
        end

        context "languages" do
          let(:subject_symbol) { :foreign_languages }

          context "base" do
            let(:school) { base_school }

            it { is_expected.to eq(2_000) }
          end

          context "uplift" do
            let(:school) { uplift_school }

            it { is_expected.to eq(3_000) }
          end
        end
      end
    end
  end

  describe ".max_award_amount_in_pounds" do
    specify { expect(described_class.max_award_amount_in_pounds).to eq(7_500) }
  end
end
