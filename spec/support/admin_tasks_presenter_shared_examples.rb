RSpec.shared_examples "ECP and Targeted Retention Incentive Combined Journey Admin Tasks Presenter" do |policy|
  let(:claim) { create(:claim, :submitted, policy: policy) }
  let(:eligibility) { claim.eligibility }
  let(:school) { eligibility.current_school }

  subject(:presenter) { described_class.new(claim) }

  describe "attributes" do
    let!(:journey_configuration) { create(:journey_configuration, policy.to_s.underscore) }
    let(:expected_itt_year) { eligibility.itt_academic_year }

    it {
      is_expected.to have_attributes(
        employment: [[I18n.t("admin.current_school"), presenter.display_school(eligibility.current_school)]],
        identity_confirmation: [["Current school", school.name], ["Contact number", school.phone_number]],
        census_subjects_taught: [["Subject", "Mathematics"]],
        qualifications: [["Qualification", "Postgraduate initial teacher training (ITT)"],
          ["ITT start year", "In the academic year #{expected_itt_year.start_year} to #{expected_itt_year.end_year}"],
          ["ITT subject", "Mathematics"]]
      )
    }
  end

  # The following is moved from an old spec. Haven't taken the effort to refactor it here.
  describe "#qualifications" do
    [
      {qualification: :assessment_only, qualification_text: "Assessment only", year_text: "end", subject_text: :physics},
      {qualification: :overseas_recognition, qualification_text: "Overseas recognition", year_text: "end", subject_text: :chemistry},
      {qualification: :postgraduate_itt, qualification_text: "Postgraduate initial teacher training (ITT)", year_text: "start", subject_text: :foreign_languages},
      {qualification: :undergraduate_itt, qualification_text: "Undergraduate initial teacher training (ITT)", year_text: "end", subject_text: :mathematics}
    ].each do |spec|
      context "with qualification #{spec[:qualification]}" do
        let(:claim) do
          build(
            :claim,
            academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2023)),
            policy: policy,
            eligibility: build(
              :"#{policy.to_s.underscore}_eligibility",
              eligible_itt_subject: spec[:subject_text],
              itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020)),
              qualification: qualification
            )
          )
        end

        let(:qualification) { spec[:qualification] }

        it "returns array with qualification #{spec[:qualification_text]}" do
          expect(presenter.qualifications).to include(
            ["Qualification", spec[:qualification_text]]
          )
        end

        it "returns array with year #{spec[:year_text]}" do
          expect(presenter.qualifications).to include(
            ["ITT #{spec[:year_text]} year", "In the academic year 2020 to 2021"]
          )
        end

        it "returns array with subject #{spec[:subject_text]}" do
          expect(presenter.qualifications).to include(
            ["ITT subject", I18n.t("additional_payments.forms.eligible_itt_subject.answers.#{spec[:subject_text]}")]
          )
        end
      end
    end
  end
end
