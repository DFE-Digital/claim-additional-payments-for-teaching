require "rails_helper"

RSpec.describe Admin::Claims::EmploymentHistory::CreateEmploymentForm, type: :model do
  let(:claim) do
    create(
      :claim,
      :submitted,
      policy: Policies::InternationalRelocationPayments
    )
  end

  let(:school) { create(:school) }

  let(:form) { described_class.new(claim, params: params) }

  describe "validations" do
    context "when created_by is missing" do
      let(:params) do
        {}
      end

      it "is invalid with an appropriate error message" do
        expect(form).not_to be_valid

        expect(form.errors[:created_by]).to include("can't be blank")
      end
    end

    context "when no school is selected" do
      let(:params) do
        {
          school_id: nil
        }
      end

      it "is invalid with an appropriate error message" do
        expect(form).not_to be_valid

        expect(form.errors[:school_search]).to include("Select a school")
      end
    end

    context "when employment_contract_of_at_least_one_year is invalid" do
      let(:params) do
        {
          employment_contract_of_at_least_one_year: nil
        }
      end

      it "is invalid with an appropriate error message" do
        expect(form).not_to be_valid

        expect(form.errors[:employment_contract_of_at_least_one_year]).to(
          include(
            "Select whether the employment contract is of at least one year"
          )
        )
      end
    end

    context "when subject_employed_to_teach is invalid" do
      let(:params) do
        {
          subject_employed_to_teach: "chemistry"
        }
      end

      it "is invalid with an appropriate error message" do
        expect(form).not_to be_valid

        expect(form.errors[:subject_employed_to_teach]).to include(
          "Select a subject employed to teach"
        )
      end
    end

    context "when met_minimum_teaching_hours is invalid" do
      subject(:form) do
        described_class.new(
          claim,
          params: {
            met_minimum_teaching_hours: nil
          }
        )
      end

      it "is invalid with an appropriate error message" do
        expect(form).not_to be_valid

        expect(form.errors[:met_minimum_teaching_hours]).to include(
          "Select whether the minimum teaching hours were met"
        )
      end
    end

    context "when employment_start_date is missing" do
      subject(:form) do
        described_class.new(
          claim,
          params: {
            employment_start_date: nil,
            employment_end_date: Date.new(2023, 12, 31)
          }
        )
      end

      it "is invalid with an appropriate error message" do
        expect(form).not_to be_valid

        expect(form.errors[:employment_start_date]).to include(
          "Enter an employment start date"
        )
      end
    end

    context "when employment_end_date is missing" do
      subject(:form) do
        described_class.new(
          claim,
          params: {
            employment_start_date: Date.new(2023, 1, 1),
            employment_end_date: nil
          }
        )
      end

      it "is invalid with an appropriate error message" do
        expect(form).not_to be_valid

        expect(form.errors[:employment_end_date]).to include(
          "Enter an employment end date"
        )
      end
    end

    context "when employment_start_date is after employment_end_date" do
      let(:params) do
        {
          employment_start_date: Date.new(2023, 12, 31),
          employment_end_date: Date.new(2023, 1, 1)
        }
      end

      it "is invalid with an appropriate error message" do
        expect(form).not_to be_valid

        expect(form.errors[:employment_end_date]).to include(
          "The employment end date must be after the employment start date"
        )
      end
    end

    context "when employment_start_date is in the future" do
      let(:params) do
        {
          employment_start_date: Date.tomorrow,
          employment_end_date: Date.today + 2.days
        }
      end

      it "is invalid with an appropriate error message" do
        expect(form).not_to be_valid

        expect(form.errors[:employment_start_date]).to include(
          "The employment start date must be in the past"
        )
      end
    end

    context "when employment_end_date is in the future" do
      let(:params) do
        {
          employment_start_date: Date.yesterday,
          employment_end_date: Date.tomorrow
        }
      end

      it "is invalid with an appropriate error message" do
        expect(form).not_to be_valid

        expect(form.errors[:employment_end_date]).to include(
          "The employment end date must be in the past"
        )
      end
    end
  end

  describe "#save" do
    let(:created_by) { create(:dfe_signin_user) }

    let(:params) do
      {
        school_id: school.id,
        school_search: school.name,
        employment_contract_of_at_least_one_year: true,
        employment_start_date: Date.new(2023, 1, 1),
        employment_end_date: Date.new(2023, 12, 31),
        met_minimum_teaching_hours: true,
        subject_employed_to_teach: "physics",
        created_by: created_by
      }
    end

    it "creates a new employment history" do
      travel_to DateTime.new(2025, 6, 1, 0, 0, 0) do
        expect(form.save).to be true
      end

      eligibility = claim.reload.eligibility

      employment_history = eligibility.employment_history.first

      expect(employment_history.school).to eq(school)
      expect(employment_history.employment_contract_of_at_least_one_year).to be true
      expect(employment_history.employment_start_date).to eq(Date.new(2023, 1, 1))
      expect(employment_history.employment_end_date).to eq(Date.new(2023, 12, 31))
      expect(employment_history.met_minimum_teaching_hours).to be true
      expect(employment_history.subject_employed_to_teach).to eq("physics")
      expect(employment_history.created_by).to eq(created_by)
      expect(employment_history.created_at).to eq(DateTime.new(2025, 6, 1, 0, 0, 0))
    end

    it "doesn't overwrite existing employment history" do
      employment = Policies::InternationalRelocationPayments::EmploymentHistory::Employment.new(
        school: school,
        employment_contract_of_at_least_one_year: false,
        employment_start_date: Date.new(2022, 1, 1),
        employment_end_date: Date.new(2022, 12, 31),
        met_minimum_teaching_hours: false,
        subject_employed_to_teach: "physics",
        created_by: create(:dfe_signin_user)
      )

      claim.eligibility.employment_history = [employment]

      expect { form.save }.to(
        change { claim.eligibility.employment_history.count }.from(1).to(2)
      )
    end
  end
end
