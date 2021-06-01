require "rails_helper"

RSpec.describe Claims::ShowHelper do
  let(:claim) { build(:claim, policy: policy) }

  describe "#claim_submitted_title(claim)" do
    context "with a StudentLoans policy" do
      let(:policy) { StudentLoans }

      it "returns the correct content block" do
        expect(helper.claim_submitted_title(claim)).to include("Claim submitted")
      end
    end

    context "with a EarlyCareerPayments policy" do
      let(:policy) { EarlyCareerPayments }

      it "returns the correct content block" do
        expect(helper.claim_submitted_title(claim)).to include("Application complete")
      end
    end
  end

  describe "#shared_view_css_class_size(claim)" do
    context "with a StudentLoans policy" do
      let(:policy) { StudentLoans }

      it "returns the correct css sizing" do
        expect(helper.shared_view_css_class_size(claim)).to eq "xl"
      end
    end

    context "with a EarlyCareerPayments policy" do
      let(:policy) { EarlyCareerPayments }

      it "returns the correct css sizing" do
        expect(helper.shared_view_css_class_size(claim)).to eq "l"
      end
    end
  end

  describe "#base_and_uplift_award_amounts(claim)" do
    context "with a StudentLoans policy" do
      let(:policy) { StudentLoans }

      it "returns nil" do
        expect(helper.base_and_uplift_award_amounts(claim, nil)).to be_nil
      end
    end

    context "with a EarlyCareerPayments policy" do
      let(:policy) { EarlyCareerPayments }

      describe "Chemistry/Physics/Foreign Languages" do
        it "returns 2000.00 and 3000.00 for claim academic year 2021/2022" do
          claim.eligibility.itt_academic_year_2020_2021!
          claim.eligibility.itt_subject_chemistry!
          year = 2021

          expect(helper.base_and_uplift_award_amounts(claim, year)).to include({base: 0.0}, {uplifted: 0.0})
        end

        it "returns 2000.00 and 3000.00 for claim academic year 2022/2023" do
          claim.eligibility.itt_academic_year_2020_2021!
          claim.eligibility.itt_subject_foreign_languages!
          year = 2022

          expect(helper.base_and_uplift_award_amounts(claim, year)).to include({base: 2000.00}, {uplifted: 3000.0})
        end
      end

      describe "Mathematics" do
        context "with itt_academic_year '2018 to 2019'" do
          it "returns 5000.00 and 7500.00 for claim academic year 2021/2022" do
            claim.eligibility.itt_academic_year_2018_2019!
            claim.eligibility.itt_subject_mathematics!
            year = 2021

            expect(helper.base_and_uplift_award_amounts(claim, year)).to include({base: 5000.00}, {uplifted: 7500.0})
          end

          it "returns 5000.00 and 7500.00 for claim academic year 2022/2023" do
            claim.eligibility.itt_academic_year_2018_2019!
            claim.eligibility.itt_subject_mathematics!
            year = 2022

            expect(helper.base_and_uplift_award_amounts(claim, year)).to include({base: 0.0}, {uplifted: 0.0})
          end
        end

        context "with itt_academic_year '2019 to 2020'" do
          it "returns 5000.00 and 7500.00" do
            claim.eligibility.itt_academic_year_2019_2020!
            claim.eligibility.itt_subject_mathematics!
            year = 2022

            expect(helper.base_and_uplift_award_amounts(claim, year)).to include({base: 5000.00}, {uplifted: 7500.0})
          end
        end

        context "with itt_academic_year '2020 to 2021'" do
          it "returns 2000.00 and 3000.00" do
            claim.eligibility.itt_academic_year_2020_2021!
            claim.eligibility.itt_subject_mathematics!
            year = 2022

            expect(helper.base_and_uplift_award_amounts(claim, year)).to include({base: 2000.0}, {uplifted: 3000.0})
          end
        end
      end
    end
  end
end
