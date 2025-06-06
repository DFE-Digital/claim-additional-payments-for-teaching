require "rails_helper"

RSpec.describe Admin::Claims::EmploymentHistory::DestroyEmploymentForm do
  describe "#save" do
    it "removes the employment" do
      claim = create(
        :claim,
        :submitted,
        policy: Policies::InternationalRelocationPayments
      )

      employment_1 = Policies::InternationalRelocationPayments::EmploymentHistory::Employment.new(
        id: "1111-1111-1111-1111",
        school: create(:school),
        employment_start_date: Date.new(2023, 5, 1),
        employment_end_date: Date.new(2024, 4, 1),
        subject_employed_to_teach: "Physics",
        met_minimum_teaching_hours: true
      )

      employment_2 = Policies::InternationalRelocationPayments::EmploymentHistory::Employment.new(
        id: "1111-1111-1111-1112",
        school: create(:school),
        employment_start_date: Date.new(2023, 5, 1),
        employment_end_date: Date.new(2024, 4, 1),
        subject_employed_to_teach: "Physics",
        met_minimum_teaching_hours: true
      )

      dfe_signin_user = create(:dfe_signin_user)

      claim.eligibility.employment_history = [
        employment_1,
        employment_2
      ]

      claim.save!

      form = described_class.new(
        claim,
        params: {
          employment_id: employment_1.id,
          deleted_by: dfe_signin_user
        }
      )

      travel_to DateTime.new(2025, 6, 1, 0, 0, 0) do
        form.save!
      end

      claim.reload

      expect(
        claim.eligibility.employment_history.reject(&:deleted?)
      ).to eq([employment_2])

      deleted_employment = claim.eligibility.employment_history.find(&:deleted?)

      expect(deleted_employment).to eq(employment_1)

      expect(deleted_employment.deleted_by).to eq(dfe_signin_user)

      expect(
        deleted_employment.deleted_at
      ).to eq(DateTime.new(2025, 6, 1, 0, 0, 0))
    end
  end
end
