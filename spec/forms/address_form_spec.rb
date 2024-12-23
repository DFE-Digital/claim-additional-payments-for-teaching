require "rails_helper"

RSpec.describe AddressForm, type: :model do
  subject(:form) do
    described_class.new(
      journey: journey,
      params: params,
      journey_session: journey_session
    )
  end

  let(:journey) { Journeys::TeacherStudentLoanReimbursement }
  let(:journey_session) { build(:student_loans_session) }
  let(:slug) { "address" }
  let(:params) { ActionController::Parameters.new({slug:, claim: claim_params}) }
  let(:claim_params) do
    {
      address_line_1: "123",
      address_line_2: "Main Street",
      address_line_3: "Some City",
      address_line_4: "",
      postcode: "PE11 3EW"
    }
  end

  it { is_expected.to be_a(Form) }

  describe "validations" do
    context "required address lines provided" do
      it { is_expected.to be_valid }
    end

    context "required address lines blank" do
      let(:claim_params) do
        {
          address_line_1: "",
          address_line_2: "",
          address_line_3: "",
          address_line_4: "",
          postcode: ""
        }
      end

      it "is invalid with presence errors" do
        is_expected.not_to be_valid

        expect(form.errors.size).to eq 4
        expect(form.errors[:address_line_1]).to eq([form.i18n_errors_path(:address_line_1_blank)])
        expect(form.errors[:address_line_2]).to eq([form.i18n_errors_path(:address_line_2_blank)])
        expect(form.errors[:address_line_3]).to eq([form.i18n_errors_path(:address_line_3_blank)])
        expect(form.errors[:postcode]).to eq([form.i18n_errors_path(:postcode_blank)])
      end
    end

    context "address lines too long" do
      let(:over_one_hundred_chars) { Array.new(101) { [("a".."z"), ("A".."Z")].map(&:to_a).flatten.sample }.join }
      let(:claim_params) do
        {
          address_line_1: over_one_hundred_chars,
          address_line_2: over_one_hundred_chars,
          address_line_3: over_one_hundred_chars,
          address_line_4: over_one_hundred_chars,
          postcode: "AB12 3CDXXXX"
        }
      end

      it "is invalid with too long errors" do
        is_expected.not_to be_valid

        expect(form.errors.size).to eq 6
        expect(form.errors[:address_line_1]).to eq([form.i18n_errors_path(:address_line_max_chars)])
        expect(form.errors[:address_line_2]).to eq([form.i18n_errors_path(:address_line_max_chars)])
        expect(form.errors[:address_line_3]).to eq([form.i18n_errors_path(:address_line_max_chars)])
        expect(form.errors[:address_line_4]).to eq([form.i18n_errors_path(:address_line_max_chars)])
        expect(form.errors[:postcode]).to contain_exactly(form.i18n_errors_path(:postcode_max_chars), form.i18n_errors_path(:postcode_format))
      end
    end

    context "address lines with format errors" do
      context "with unpermitted characters" do
        let(:claim_params) do
          {
            address_line_1: "#123",
            address_line_2: "Main $treet",
            address_line_3: "$ome City",
            address_line_4: "$som County",
            postcode: "XXX XXXX"
          }
        end

        it "is invalid with format errors" do
          is_expected.not_to be_valid

          expect(form.errors.size).to eq 5
          expect(form.errors[:address_line_1]).to eq([form.i18n_errors_path(:address_format)])
          expect(form.errors[:address_line_2]).to eq([form.i18n_errors_path(:address_format)])
          expect(form.errors[:address_line_3]).to eq([form.i18n_errors_path(:address_format)])
          expect(form.errors[:address_line_4]).to eq([form.i18n_errors_path(:address_format)])
          expect(form.errors[:postcode]).to eq([form.i18n_errors_path(:postcode_format)])
        end
      end

      context "with invalid looking address" do
        context "with an invalid line 1" do
          let(:claim_params) do
            {
              address_line_1: ".",
              address_line_2: "10 Downing Street",
              address_line_3: "London",
              postcode: "SW1A 2AA"
            }
          end

          it "is invalid with format errors" do
            is_expected.not_to be_valid

            expect(form.errors.size).to eq 1
            expect(form.errors[:address_line_1]).to eq([form.i18n_errors_path(:address_format)])
          end
        end

        context "with an invalid line 2" do
          let(:claim_params) do
            {
              address_line_1: "Flat 1",
              address_line_2: ".",
              address_line_3: "London",
              postcode: "SW1A 2AA"
            }
          end

          it "is invalid with format errors" do
            is_expected.not_to be_valid

            expect(form.errors.size).to eq 1
            expect(form.errors[:address_line_2]).to eq([form.i18n_errors_path(:address_format)])
          end
        end

        context "with an invalid line 3" do
          let(:claim_params) do
            {
              address_line_1: "Flat 1",
              address_line_2: "10 Downing Street",
              address_line_3: "123",
              postcode: "SW1A 2AA"
            }
          end

          it "is invalid with format errors" do
            is_expected.not_to be_valid

            expect(form.errors.size).to eq 1
            expect(form.errors[:address_line_3]).to eq([form.i18n_errors_path(:address_format)])
          end
        end
      end
    end
  end

  describe "#save" do
    context "valid params" do
      context "all required address lines provided" do
        before { form.save }

        it "updates the session" do
          answers = journey_session.answers
          expect(answers.address_line_1).to eq "123"
          expect(answers.address_line_2).to eq "Main Street"
          expect(answers.address_line_3).to eq "Some City"
          expect(answers.address_line_4).to eq ""
          expect(answers.postcode).to eq "PE11 3EW"
        end
      end

      context "all address lines provided" do
        let(:claim_params) do
          {
            address_line_1: "123",
            address_line_2: "Main Street",
            address_line_3: "Some City",
            address_line_4: "Some County",
            postcode: "PE11 3EW"
          }
        end

        before { form.save }

        it "udpates the session" do
          answers = journey_session.answers
          expect(answers.address_line_1).to eq "123"
          expect(answers.address_line_2).to eq "Main Street"
          expect(answers.address_line_3).to eq "Some City"
          expect(answers.address_line_4).to eq "Some County"
          expect(answers.postcode).to eq "PE11 3EW"
        end
      end
    end

    context "invalid params" do
      let(:claim_params) do
        {
          address_line_1: "",
          address_line_2: "",
          address_line_3: "",
          address_line_4: "",
          postcode: ""
        }
      end

      before { form.save }

      it "does not update the session" do
        answers = journey_session.answers
        expect(answers.address_line_1).to be_nil
        expect(answers.address_line_2).to be_nil
        expect(answers.address_line_3).to be_nil
        expect(answers.address_line_4).to be_nil
        expect(answers.postcode).to be_nil
      end
    end
  end
end
