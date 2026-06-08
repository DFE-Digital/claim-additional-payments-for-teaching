require "rails_helper"

RSpec.describe Admin::AmendmentForm, type: :model do
  let(:admin_user) { create(:dfe_signin_user) }

  describe "#date_of_birth" do
    context "when out of range ie invalid date" do
      subject do
        described_class.new(
          claim: create(:claim, :submitted),
          admin_user:,
          params: {
            "date_of_birth(1i)": "13",
            "date_of_birth(2i)": "13",
            "date_of_birth(3i)": "1970"
          }
        )
      end

      it "set date_of_birth to nil" do
        expect(subject.date_of_birth).to be_nil
      end
    end
  end

  describe "validations" do
    let(:claim) { build(:claim, :submitted) }
    let(:admin_user) { create(:dfe_signin_user) }
    let(:notes) { "made some changes" }

    subject do
      described_class.new(
        claim:,
        admin_user:,
        params: {
          notes:
        }
      )
    end

    it { is_expected.to validate_presence_of(:date_of_birth).with_message("Enter a date of birth") }

    it do
      is_expected.to(
        validate_presence_of(:banking_name)
        .with_message("Enter a name on the account")
      )
    end
  end

  describe "#save" do
    let(:claim) { create(:claim, :submitted) }
    let(:admin_user) { create(:dfe_signin_user) }
    let(:notes) { "made some changes" }

    context "when student_loan_plan is empty string" do
      subject do
        described_class.new(
          claim:,
          admin_user:,
          params: {
            notes:,
            student_loan_plan: ""
          }
        )
      end

      it "saves it as nil" do
        subject.valid?
        subject.save
        expect(claim.reload.student_loan_plan).to be_nil
      end
    end

    context "when setting the banking name" do
      context "when the banking name is set by a non service admin" do
        it "is not updated" do
          claim = create(
            :claim,
            :submitted,
            banking_name: "Old banking name"
          )

          admin_user = create(:dfe_signin_user, :service_operator)

          form = described_class.new(
            claim: claim,
            admin_user: admin_user,
            params: {
              notes: "made some changes",
              banking_name: "New banking name"
            }
          )

          expect(form).not_to be_valid

          expect(form.errors[:banking_name]).to include(
            "You do not have permission to change the banking name"
          )
        end
      end

      context "when the banking name is set by a service admin" do
        it "is updated" do
          claim = create(
            :claim,
            :submitted,
            banking_name: "Old banking name"
          )

          admin_user = create(:dfe_signin_user, :service_admin)

          form = described_class.new(
            claim: claim,
            admin_user: admin_user,
            params: {
              notes: "made some changes",
              banking_name: "New banking name"
            }
          )

          expect(form).to be_valid

          expect { form.save }.to(
            change { claim.reload.banking_name }
              .from("Old banking name")
              .to("New banking name")
          )
        end
      end

      context "setting the award amount" do
        context "when the award amount is amendable" do
          it "is updated" do
            claim = create(
              :claim,
              :submitted,
              eligibility_attributes: {
                award_amount: 1000
              }
            )

            form = described_class.new(
              claim: claim,
              admin_user:,
              params: {
                notes: "made some changes",
                award_amount: 2000
              }
            )

            expect(form).to be_valid

            expect { form.save }.to(
              change { claim.reload.eligibility.award_amount }
                .from(1000)
                .to(2000)
            )
          end
        end

        context "when the award amount is not amendable" do
          it "is not updated" do
            claim = create(
              :claim,
              :submitted,
              policy: Policies::EarlyYearsPayments,
              eligibility_attributes: {
                award_amount: 1000
              }
            )

            form = described_class.new(
              claim: claim,
              admin_user:,
              params: {
                notes: "made some changes",
                award_amount: 2000
              }
            )

            expect(form).not_to be_valid

            expect(form.errors[:award_amount]).to include(
              "Award amount cannot be changed for this policy"
            )

            expect { form.save }.to_not(
              change { claim.reload.eligibility.award_amount }
            )
          end
        end
      end
    end

    context "when a value is missing in the params" do
      it "is unchanged from the claim's value" do
        claim = create(
          :claim,
          :submitted,
          email_address: "test@example.com",
          date_of_birth: Date.new(1970, 1, 1)
        )

        form = described_class.new(
          claim: claim,
          admin_user:,
          params: {
            notes: "made some changes",
            email_address: "test2@example.com"
          }
        )

        expect { expect(form.save).to be true }.to_not(
          change { claim.reload.date_of_birth }
        )
      end
    end
  end
end
