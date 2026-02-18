require "rails_helper"

RSpec.describe Admin::Amendments::FurtherEducationPaymentsForm, type: :model do
  let(:admin_user) { create(:dfe_signin_user) }

  describe "#load_data_from_claim" do
    let(:claim) do
      create(:claim, :further_education, :submitted,
        eligibility_attributes: {
          further_education_teaching_start_year: "2023"
        })
    end

    it "loads further_education_teaching_start_year from the eligibility" do
      form = described_class.new(claim: claim, admin_user: admin_user)
      form.load_data_from_claim

      expect(form.further_education_teaching_start_year).to eq("2023")
    end
  end

  describe "#save" do
    let(:notes) { "Amending claim based on provider feedback" }

    let(:provider_verification_attributes) do
      {
        contract_type: "permanent",
        teacher_reference_number: "1234567",
        provider_verification_teaching_responsibilities: true,
        provider_verification_teaching_start_year: "2023",
        provider_verification_teaching_qualification: "yes",
        provider_verification_contract_type: "permanent",
        provider_verification_performance_measures: false,
        provider_verification_disciplinary_action: false,
        provider_verification_teaching_hours_per_week: "more_than_20",
        provider_verification_half_teaching_hours: true,
        provider_verification_half_timetabled_teaching_time: true,
        provider_verification_continued_employment: true
      }
    end

    context "when the provider verification task is not present" do
      let(:claim) do
        create(:claim, :further_education, :submitted,
          eligibility_attributes: {
            further_education_teaching_start_year: "2023"
          })
      end

      it "saves the amendment without creating a provider verification task" do
        form = described_class.new(claim: claim, admin_user: admin_user, notes: notes)
        form.load_data_from_claim
        form.further_education_teaching_start_year = "2024"

        expect(form.save).to be_truthy

        claim.reload
        expect(claim.eligibility.further_education_teaching_start_year).to eq("2024")
        expect(claim.tasks.where(name: "fe_provider_verification_v2")).to be_empty
        expect(claim.notes.where(label: "fe_provider_verification_v2")).to be_empty
      end
    end

    context "when further_education_teaching_start_year is not changed" do
      let(:claim) do
        create(:claim, :further_education, :submitted,
          eligibility_attributes: provider_verification_attributes.merge(
            further_education_teaching_start_year: "2023"
          ))
      end

      before do
        AutomatedChecks::ClaimVerifiers::FeProviderVerificationV2.new(claim).perform
      end

      it "does not rerun the provider verification task" do
        original_task = claim.tasks.find_by(name: "fe_provider_verification_v2")
        expect(original_task).to be_present

        form = described_class.new(claim: claim, admin_user: admin_user, notes: notes)
        form.load_data_from_claim
        form.teacher_reference_number = "7654321"

        expect(form.save).to be_truthy

        claim.reload
        task = claim.tasks.find_by(name: "fe_provider_verification_v2")
        expect(task.id).to eq(original_task.id)
        expect(claim.notes.where(label: "fe_provider_verification_v2")).to be_empty
      end
    end

    context "when provider verification task is present and further_education_teaching_start_year is changed" do
      let(:claim) do
        create(:claim, :further_education, :submitted,
          eligibility_attributes: provider_verification_attributes.merge(
            further_education_teaching_start_year: "2023"
          ))
      end

      before do
        AutomatedChecks::ClaimVerifiers::FeProviderVerificationV2.new(claim).perform
      end

      it "destroys the old task, reruns the automated check and creates a note" do
        original_task = claim.tasks.find_by(name: "fe_provider_verification_v2")
        expect(original_task.passed).to be(true)

        form = described_class.new(claim: claim, admin_user: admin_user, notes: notes)
        form.load_data_from_claim
        form.further_education_teaching_start_year = "2024"

        expect(form.save).to be_truthy

        claim.reload

        expect(claim.tasks.find_by(id: original_task.id)).to be_nil

        new_task = claim.tasks.find_by(name: "fe_provider_verification_v2")
        expect(new_task).to be_present
        expect(new_task.passed).to be(false)

        note = claim.notes.find_by(label: "fe_provider_verification_v2")
        expect(note).to be_present
        expect(note.body).to include("previously")
        expect(note.body).to include("passed")
        expect(note.body).to include("2023")
      end
    end
  end
end
