FactoryBot.define do
  factory :student_loans_session, class: "Journeys::TeacherStudentLoanReimbursement::Session" do
    journey { "student-loans" }

    trait :with_employment_proof do
      after(:create) do |session|
        session.employment_proofs.attach(
          io: Rails.root.join("spec/fixtures/files/employment_proof.pdf").open,
          filename: "employment_proof.pdf",
          content_type: "application/pdf"
        )
        blob_id = session.employment_proofs.blobs.last.id.to_s
        session.answers.assign_attributes(confirmed_employment_proof_blob_ids: [blob_id])
        session.save!
      end
    end
  end
end
