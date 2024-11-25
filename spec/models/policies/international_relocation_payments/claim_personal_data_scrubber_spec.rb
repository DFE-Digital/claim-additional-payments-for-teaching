require "rails_helper"

RSpec.describe Policies::InternationalRelocationPayments::ClaimPersonalDataScrubber do
  it_behaves_like(
    "a claim personal data scrubber",
    Policies::InternationalRelocationPayments
  )

  it "retains name and national insurance number for 2 years" do
    last_academic_year = Time.zone.local(AcademicYear.current.start_year, 8, 1, 12)

    approved_claim = create(
      :claim,
      :submitted,
      policy: Policies::InternationalRelocationPayments,
      national_insurance_number: "AB123456C",
      first_name: "John",
      middle_name: "James",
      surname: "Doe"
    )

    create(
      :decision,
      :approved,
      claim: approved_claim,
      created_at: last_academic_year
    )

    create(
      :payment,
      :confirmed,
      :with_figures,
      claims: [approved_claim],
      scheduled_payment_date: last_academic_year
    )

    rejected_claim = create(
      :claim,
      :submitted,
      policy: Policies::InternationalRelocationPayments,
      national_insurance_number: "AB123456C",
      first_name: "John",
      middle_name: "James",
      surname: "Doe"
    )

    create(
      :decision,
      :rejected,
      claim: rejected_claim,
      created_at: last_academic_year
    )

    claim_expected_not_to_change = create(
      :claim,
      :submitted,
      policy: Policies::InternationalRelocationPayments,
      national_insurance_number: "AB123456D",
      first_name: "Jane",
      surname: "Smith"
    )

    create(
      :decision,
      :approved,
      claim: claim_expected_not_to_change,
      created_at: last_academic_year,
      undone: true
    )

    expect { described_class.new.scrub_completed_claims }.to(
      not_change { approved_claim.reload.first_name }
      .and(
        not_change { approved_claim.reload.middle_name }
      ).and(
        not_change { approved_claim.reload.surname }
      ).and(
        not_change { approved_claim.reload.national_insurance_number }
      ).and(
        not_change { rejected_claim.reload.first_name }
      ).and(
        not_change { rejected_claim.reload.surname }
      ).and(
        not_change { rejected_claim.reload.national_insurance_number }
      )
    )

    travel_to(AcademicYear.current.start_of_autumn_term + 2.years + 2.hours) do
      expect { described_class.new.scrub_completed_claims }.to(
        change { approved_claim.reload.first_name }.to(nil)
        .and(
          change { approved_claim.reload.middle_name }.to(nil)
        ).and(
          change { approved_claim.reload.surname }.to(nil)
        ).and(
          change { approved_claim.reload.national_insurance_number }.to(nil)
        ).and(
          change { rejected_claim.reload.first_name }.to(nil)
        ).and(
          change { rejected_claim.reload.surname }.to(nil)
        ).and(
          change { rejected_claim.reload.national_insurance_number }.to(nil)
        ).and(
          not_change { claim_expected_not_to_change.reload.first_name }
        ).and(
          not_change { claim_expected_not_to_change.reload.middle_name }
        ).and(
          not_change { claim_expected_not_to_change.reload.surname }
        ).and(
          not_change { claim_expected_not_to_change.reload.national_insurance_number }
        )
      )
    end
  end
end
