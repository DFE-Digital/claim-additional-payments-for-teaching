require "rails_helper"

RSpec.describe "EYTRP claim show" do
  it "only shows links to attachments that have passed malware scans" do
    sign_in_as_service_admin

    claim = create(
      :claim,
      :submitted,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      hmrc_bank_validation_succeeded: false,
      payroll_gender: "dont_know",
      onelogin_idv_at: DateTime.new(2026, 5, 1, 9, 30, 0),
      identity_confirmed_with_onelogin: true
    )

    claim.eligibility.employment_proofs.attach(
      io: File.open(Rails.root.join("spec/fixtures/files/employment_proof.pdf")),
      filename: "employment_proof_passed_scan.pdf",
      content_type: "application/pdf"
    )

    claim.eligibility.employment_proofs.attach(
      io: File.open(Rails.root.join("spec/fixtures/files/employment_proof2.pdf")),
      filename: "employment_proof_failed_scan.pdf",
      content_type: "application/pdf"
    )

    claim.eligibility.employment_proofs.attach(
      io: File.open(Rails.root.join("spec/fixtures/files/employment_proof2.pdf")),
      filename: "employment_proof_pending_scan.pdf",
      content_type: "application/pdf"
    )

    passing_proof = claim.eligibility.employment_proofs.find do |proof|
      proof.filename.to_s == "employment_proof_passed_scan.pdf"
    end

    failing_proof = claim.eligibility.employment_proofs.find do |proof|
      proof.filename.to_s == "employment_proof_failed_scan.pdf"
    end

    pending_proof = claim.eligibility.employment_proofs.find do |proof|
      proof.filename.to_s == "employment_proof_pending_scan.pdf"
    end

    passing_proof.update!(
      malware_scan_result: "passed",
      malware_scanned_at: Time.zone.now
    )

    failing_proof.update!(
      malware_scan_result: "failed",
      malware_scanned_at: Time.zone.now
    )

    pending_proof.update!(
      malware_scan_result: "pending",
      malware_scanned_at: Time.zone.now
    )

    visit admin_claim_path(claim)

    expect(page).to have_link(
      "employment_proof_passed_scan.pdf",
      href: rails_blob_url(passing_proof)
    )

    expect(page).not_to have_link(
      "employment_proof_failed_scan.pdf",
      href: rails_blob_url(failing_proof)
    )

    expect(page).not_to have_link(
      "employment_proof_pending_scan.pdf",
      href: rails_blob_url(pending_proof)
    )

    expect(page).to have_text(
      "employment_proof_failed_scan.pdf (malware scan failed)"
    )

    expect(page).to have_text(
      "employment_proof_pending_scan.pdf (malware scan pending)"
    )
  end
end
