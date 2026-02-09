require "rails_helper"

module AutomatedChecks
  module ClaimVerifiers
    RSpec.describe Identity do
      subject(:identity) { described_class.new(**identity_args) }

      let(:data) { {} }

      before do
        if data
          body = data

          status = 200
        else
          body = {}

          status = 404
        end

        stub_qualified_teaching_statuses_show(
          trn: claim_arg.eligibility.teacher_reference_number,
          params: {
            birthdate: claim_arg.date_of_birth&.to_s,
            nino: claim_arg.national_insurance_number
          },
          body: body,
          status: status
        )
      end

      let(:identity_confirmed_with_onelogin) { nil }

      let(:claim_arg) do
        claim = create(
          :claim,
          :submitted,
          date_of_birth: Date.new(1990, 8, 23),
          first_name: "Fred",
          national_insurance_number: "AB100000C",
          reference: "AB123456",
          surname: "ELIGIBLE",
          policy: policy,
          identity_confirmed_with_onelogin: identity_confirmed_with_onelogin
        )

        policy_underscored = policy.to_s.underscore

        claim.eligibility.update!(
          attributes_for(
            :"#{policy_underscored}_eligibility",
            :eligible,
            teacher_reference_number: "1234567"
          )
        )

        claim
      end

      let(:identity_args) do
        {
          claim: claim_arg,
          dqt_teacher_status: Dqt::Client.new.teacher.find(
            claim_arg.eligibility.teacher_reference_number,
            include: "alerts,induction,routesToProfessionalStatuses"
          )
        }
      end

      describe "#perform" do
        subject(:perform) { identity.perform }

        [
          Policies::EarlyCareerPayments,
          Policies::StudentLoans
        ].each do |policy|
          context "with policy #{policy}" do
            let(:policy) { policy }

            context "with matching DQT identity" do
              let(:data) do
                {
                  dateOfBirth: claim_arg.date_of_birth,
                  firstName: claim_arg.first_name,
                  lastName: claim_arg.surname,
                  nationalInsuranceNumber: claim_arg.national_insurance_number,
                  trn: claim_arg.eligibility.teacher_reference_number
                }
              end

              it { is_expected.to be_an_instance_of(Task) }

              describe "identity confirmation task" do
                subject(:identity_confirmation_task) { claim_arg.tasks.find_by(name: "identity_confirmation") }

                before { perform }

                describe "#claim_verifier_match" do
                  subject(:claim_verifier_match) { identity_confirmation_task.claim_verifier_match }

                  it { is_expected.to eq "all" }
                end

                describe "#created_by" do
                  subject(:created_by) { identity_confirmation_task.created_by }

                  it { is_expected.to eq nil }
                end

                describe "#passed" do
                  subject(:passed) { identity_confirmation_task.passed }

                  it { is_expected.to eq true }
                end

                describe "#manual" do
                  subject(:manual) { identity_confirmation_task.manual }

                  it { is_expected.to eq false }
                end
              end

              describe "note" do
                subject(:note) { claim_arg.notes.last }

                it { is_expected.to eq(nil) }
              end

              context "without matching national insurance number" do
                let(:data) { super().merge({nationalInsuranceNumber: "AB100000B"}) }

                it { is_expected.to be_an_instance_of(Task) }

                describe "identity confirmation task" do
                  subject(:identity_confirmation_task) { claim_arg.tasks.find_by(name: "identity_confirmation") }

                  before { perform }

                  describe "#claim_verifier_match" do
                    subject(:claim_verifier_match) { identity_confirmation_task.claim_verifier_match }

                    it { is_expected.to eq "any" }
                  end

                  describe "#created_by" do
                    subject(:created_by) { identity_confirmation_task.created_by }

                    it { is_expected.to eq nil }
                  end

                  describe "#passed" do
                    subject(:passed) { identity_confirmation_task.passed }

                    it { is_expected.to eq nil }
                  end

                  describe "#manual" do
                    subject(:manual) { identity_confirmation_task.manual }

                    it { is_expected.to eq false }
                  end
                end

                describe "note" do
                  subject(:note) { claim_arg.notes.last }

                  before { perform }

                  describe "#body" do
                    subject(:body) { note.body }

                    it do
                      is_expected.to eq(
                        <<~HTML
                          [DQT Identity] - National Insurance number not matched:
                          <pre>
                            Claimant: <span class="dark-grey">"</span><span class="red">AB100000C</span><span class="dark-grey">"</span>
                            DQT:      <span class="dark-grey">"</span><span class="green">AB100000B</span><span class="dark-grey">"</span>
                          </pre>
                        HTML
                      )
                    end
                  end

                  describe "#label" do
                    subject(:label) { note.label }

                    it { is_expected.to eq("identity_confirmation") }
                  end

                  describe "#created_by" do
                    subject(:created_by) { note.created_by }

                    it { is_expected.to eq(nil) }
                  end

                  describe "#important" do
                    subject(:important) { note.important }

                    it { is_expected.to eq false }
                  end
                end
              end

              context "without matching teacher reference number" do
                let(:data) { super().merge({trn: "7654321"}) }

                it { is_expected.to be_an_instance_of(Task) }

                describe "identity confirmation task" do
                  subject(:identity_confirmation_task) { claim_arg.tasks.find_by(name: "identity_confirmation") }

                  before { perform }

                  describe "#claim_verifier_match" do
                    subject(:claim_verifier_match) { identity_confirmation_task.claim_verifier_match }

                    it { is_expected.to eq "any" }
                  end

                  describe "#created_by" do
                    subject(:created_by) { identity_confirmation_task.created_by }

                    it { is_expected.to eq nil }
                  end

                  describe "#passed" do
                    subject(:passed) { identity_confirmation_task.passed }

                    it { is_expected.to eq nil }
                  end

                  describe "#manual" do
                    subject(:manual) { identity_confirmation_task.manual }

                    it { is_expected.to eq false }
                  end
                end

                describe "note" do
                  subject(:note) { claim_arg.notes.last }

                  before { perform }

                  describe "#body" do
                    subject(:body) { note.body }

                    it do
                      is_expected.to eq(
                        <<~HTML
                          [DQT Identity] - Teacher reference number not matched:
                          <pre>
                            Claimant: <span class="dark-grey">"</span><span class="red">1234567</span><span class="dark-grey">"</span>
                            DQT:      <span class="dark-grey">"</span><span class="green">7654321</span><span class="dark-grey">"</span>
                          </pre>
                        HTML
                      )
                    end
                  end

                  describe "#label" do
                    subject(:label) { note.label }

                    it { is_expected.to eq("identity_confirmation") }
                  end

                  describe "#created_by" do
                    subject(:created_by) { note.created_by }

                    it { is_expected.to eq(nil) }
                  end

                  describe "#important" do
                    subject(:important) { note.important }

                    it { is_expected.to eq false }
                  end
                end
              end

              context "without matching first name" do
                let(:data) { super().merge({firstName: "Except"}) }

                it { is_expected.to be_an_instance_of(Task) }

                describe "identity confirmation task" do
                  subject(:identity_confirmation_task) { claim_arg.tasks.find_by(name: "identity_confirmation") }

                  before { perform }

                  describe "#claim_verifier_match" do
                    subject(:claim_verifier_match) { identity_confirmation_task.claim_verifier_match }

                    it { is_expected.to eq "any" }
                  end

                  describe "#created_by" do
                    subject(:created_by) { identity_confirmation_task.created_by }

                    it { is_expected.to eq nil }
                  end

                  describe "#passed" do
                    subject(:passed) { identity_confirmation_task.passed }

                    it { is_expected.to eq nil }
                  end

                  describe "#manual" do
                    subject(:manual) { identity_confirmation_task.manual }

                    it { is_expected.to eq false }
                  end
                end

                describe "note" do
                  subject(:note) { claim_arg.notes.last }

                  before { perform }

                  describe "#body" do
                    subject(:body) { note.body }

                    it do
                      is_expected.to eq(
                        <<~HTML
                          [DQT Identity] - First name or surname not matched:
                          <pre>
                            Claimant: <span class="dark-grey">"</span><span class="red">Fred ELIGIBLE</span><span class="dark-grey">"</span>
                            DQT:      <span class="dark-grey">"</span><span class="green">Except ELIGIBLE</span><span class="dark-grey">"</span>
                          </pre>
                        HTML
                      )
                    end
                  end

                  describe "#label" do
                    subject(:label) { note.label }

                    it { is_expected.to eq("identity_confirmation") }
                  end

                  describe "#created_by" do
                    subject(:created_by) { note.created_by }

                    it { is_expected.to eq(nil) }
                  end

                  describe "#important" do
                    subject(:important) { note.important }

                    it { is_expected.to eq false }
                  end
                end
              end

              context "without matching surname" do
                let(:data) { super().merge({lastName: "Except"}) }

                it { is_expected.to be_an_instance_of(Task) }

                describe "identity confirmation task" do
                  subject(:identity_confirmation_task) { claim_arg.tasks.find_by(name: "identity_confirmation") }

                  before { perform }

                  describe "#claim_verifier_match" do
                    subject(:claim_verifier_match) { identity_confirmation_task.claim_verifier_match }

                    it { is_expected.to eq "any" }
                  end

                  describe "#created_by" do
                    subject(:created_by) { identity_confirmation_task.created_by }

                    it { is_expected.to eq nil }
                  end

                  describe "#passed" do
                    subject(:passed) { identity_confirmation_task.passed }

                    it { is_expected.to eq nil }
                  end

                  describe "#manual" do
                    subject(:manual) { identity_confirmation_task.manual }

                    it { is_expected.to eq false }
                  end
                end

                describe "note" do
                  subject(:note) { claim_arg.notes.last }

                  before { perform }

                  describe "#body" do
                    subject(:body) { note.body }

                    it do
                      is_expected.to eq(
                        <<~HTML
                          [DQT Identity] - First name or surname not matched:
                          <pre>
                            Claimant: <span class="dark-grey">"</span><span class="red">Fred ELIGIBLE</span><span class="dark-grey">"</span>
                            DQT:      <span class="dark-grey">"</span><span class="green">Fred Except</span><span class="dark-grey">"</span>
                          </pre>
                        HTML
                      )
                    end
                  end

                  describe "#label" do
                    subject(:label) { note.label }

                    it { is_expected.to eq("identity_confirmation") }
                  end

                  describe "#created_by" do
                    subject(:created_by) { note.created_by }

                    it { is_expected.to eq(nil) }
                  end

                  describe "#important" do
                    subject(:important) { note.important }

                    it { is_expected.to eq false }
                  end
                end
              end

              context "without matching date of birth" do
                let(:data) { super().merge({dateOfBirth: (claim_arg.date_of_birth + 1.day).to_s}) }

                it { is_expected.to be_an_instance_of(Task) }

                describe "identity confirmation task" do
                  subject(:identity_confirmation_task) { claim_arg.tasks.find_by(name: "identity_confirmation") }

                  before { perform }

                  describe "#claim_verifier_match" do
                    subject(:claim_verifier_match) { identity_confirmation_task.claim_verifier_match }

                    it { is_expected.to eq "any" }
                  end

                  describe "#created_by" do
                    subject(:created_by) { identity_confirmation_task.created_by }

                    it { is_expected.to eq nil }
                  end

                  describe "#passed" do
                    subject(:passed) { identity_confirmation_task.passed }

                    it { is_expected.to eq nil }
                  end

                  describe "#manual" do
                    subject(:manual) { identity_confirmation_task.manual }

                    it { is_expected.to eq false }
                  end
                end

                describe "note" do
                  subject(:note) { claim_arg.notes.last }

                  before { perform }

                  describe "#body" do
                    subject(:body) { note.body }

                    it do
                      is_expected.to eq(
                        <<~HTML
                          [DQT Identity] - Date of birth not matched:
                          <pre>
                            Claimant: <span class="dark-grey">"</span><span class="red">1990-08-23</span><span class="dark-grey">"</span>
                            DQT:      <span class="dark-grey">"</span><span class="green">1990-08-24</span><span class="dark-grey">"</span>
                          </pre>
                        HTML
                      )
                    end
                  end

                  describe "#label" do
                    subject(:label) { note.label }

                    it { is_expected.to eq("identity_confirmation") }
                  end

                  describe "#created_by" do
                    subject(:created_by) { note.created_by }

                    it { is_expected.to eq(nil) }
                  end

                  describe "#important" do
                    subject(:important) { note.important }

                    it { is_expected.to eq false }
                  end
                end
              end

              context "with admin claims tasks identity confirmation passed" do
                let(:claim_arg) do
                  create(
                    :claim,
                    :submitted,
                    date_of_birth: Date.new(1990, 8, 23),
                    first_name: "Fred",
                    national_insurance_number: "AB100000C",
                    reference: "AB123456",
                    surname: "ELIGIBLE",
                    tasks: [build(:task, name: :identity_confirmation, claim_verifier_match: :all)],
                    eligibility_attributes: {teacher_reference_number: "1234567"}
                  )
                end

                it { is_expected.to eq(nil) }

                describe "identity confirmation task" do
                  subject(:identity_confirmation_task) { claim_arg.tasks.find_by(name: "identity_confirmation") }

                  before { perform }

                  describe "#claim_verifier_match" do
                    subject(:claim_verifier_match) { identity_confirmation_task.claim_verifier_match }

                    it { is_expected.to eq "all" }
                  end

                  describe "#created_by" do
                    subject(:created_by) { identity_confirmation_task.created_by }

                    it { is_expected.to be_an_instance_of(DfeSignIn::User) }
                  end

                  describe "#passed" do
                    subject(:passed) { identity_confirmation_task.passed }

                    it { is_expected.to eq true }
                  end

                  describe "#manual" do
                    subject(:manual) { identity_confirmation_task.manual }

                    it { is_expected.to eq true }
                  end
                end

                describe "note" do
                  subject(:note) { claim_arg.notes.last }

                  before { perform }

                  it { is_expected.to eq(nil) }
                end
              end

              context "with teacher status alert" do
                let(:data) do
                  super().merge(
                    alerts: [
                      {
                        startDate: "2026-02-03",
                        endDate: nil
                      }
                    ]
                  )
                end

                it { is_expected.to be_an_instance_of(Task) }

                describe "identity confirmation task" do
                  subject(:identity_confirmation_task) { claim_arg.tasks.find_by(name: "identity_confirmation") }

                  before { perform }

                  describe "#claim_verifier_match" do
                    subject(:claim_verifier_match) { identity_confirmation_task.claim_verifier_match }

                    it { is_expected.to eq "any" }
                  end

                  describe "#created_by" do
                    subject(:created_by) { identity_confirmation_task.created_by }

                    it { is_expected.to eq nil }
                  end

                  describe "#passed" do
                    subject(:passed) { identity_confirmation_task.passed }

                    it { is_expected.to eq nil }
                  end

                  describe "#manual" do
                    subject(:manual) { identity_confirmation_task.manual }

                    it { is_expected.to eq false }
                  end
                end

                describe "note" do
                  subject(:note) { claim_arg.notes.last }

                  before { perform }

                  describe "#body" do
                    subject(:body) { note.body }

                    it { is_expected.to eq("IMPORTANT: Teacher’s identity has an active alert. Speak to manager before checking this claim.") }
                  end

                  describe "#label" do
                    subject(:label) { note.label }

                    it { is_expected.to eq("identity_confirmation") }
                  end

                  describe "#created_by" do
                    subject(:created_by) { note.created_by }

                    it { is_expected.to eq(nil) }
                  end

                  describe "#important" do
                    subject(:important) { note.important }

                    it { is_expected.to eq true }
                  end
                end
              end

              context "when claim values have extra whitespace" do
                let(:claim_arg) do
                  claim = create(
                    :claim,
                    :submitted,
                    date_of_birth: Date.new(1990, 8, 23),
                    first_name: "   Fred",
                    national_insurance_number: " AB100000C ",
                    reference: "AB123456",
                    surname: "ELIGIBLE ",
                    policy: policy
                  )

                  policy_underscored = policy.to_s.underscore

                  claim.eligibility.update!(
                    attributes_for(
                      :"#{policy_underscored}_eligibility",
                      :eligible,
                      teacher_reference_number: " 1234567   "
                    )
                  )

                  claim
                end

                describe "identity confirmation task" do
                  subject(:identity_confirmation_task) { claim_arg.tasks.find_by(name: "identity_confirmation") }

                  before { perform }

                  describe "#claim_verifier_match" do
                    subject(:claim_verifier_match) { identity_confirmation_task.claim_verifier_match }

                    it { is_expected.to eq "all" }
                  end

                  describe "#created_by" do
                    subject(:created_by) { identity_confirmation_task.created_by }

                    it { is_expected.to eq nil }
                  end

                  describe "#passed" do
                    subject(:passed) { identity_confirmation_task.passed }

                    it { is_expected.to eq true }
                  end

                  describe "#manual" do
                    subject(:manual) { identity_confirmation_task.manual }

                    it { is_expected.to eq false }
                  end
                end

                describe "note" do
                  subject(:note) { claim_arg.notes.last }

                  it { is_expected.to eq(nil) }
                end
              end

              context "without multiple matches" do
                let(:data) do
                  super().merge(
                    {
                      dateOfBirth: (claim_arg.date_of_birth + 1.day).to_s,
                      firstName: "Except"
                    }
                  )
                end

                it { is_expected.to be_an_instance_of(Task) }

                describe "identity confirmation task" do
                  subject(:identity_confirmation_task) { claim_arg.tasks.find_by(name: "identity_confirmation") }

                  before { perform }

                  describe "#claim_verifier_match" do
                    subject(:claim_verifier_match) { identity_confirmation_task.claim_verifier_match }

                    it { is_expected.to eq "any" }
                  end

                  describe "#created_by" do
                    subject(:created_by) { identity_confirmation_task.created_by }

                    it { is_expected.to eq nil }
                  end

                  describe "#passed" do
                    subject(:passed) { identity_confirmation_task.passed }

                    it { is_expected.to eq nil }
                  end

                  describe "#manual" do
                    subject(:manual) { identity_confirmation_task.manual }

                    it { is_expected.to eq false }
                  end
                end

                describe "first name or surname note" do
                  subject(:note) { claim_arg.notes.find_by("body LIKE ?", "[DQT Identity] - First name or surname not matched%") }

                  before { perform }

                  describe "#body" do
                    subject(:body) { note.body }

                    it do
                      is_expected.to eq(
                        <<~HTML
                          [DQT Identity] - First name or surname not matched:
                          <pre>
                            Claimant: <span class="dark-grey">"</span><span class="red">Fred ELIGIBLE</span><span class="dark-grey">"</span>
                            DQT:      <span class="dark-grey">"</span><span class="green">Except ELIGIBLE</span><span class="dark-grey">"</span>
                          </pre>
                        HTML
                      )
                    end
                  end

                  describe "#label" do
                    subject(:label) { note.label }

                    it { is_expected.to eq("identity_confirmation") }
                  end

                  describe "#created_by" do
                    subject(:created_by) { note.created_by }

                    it { is_expected.to eq(nil) }
                  end

                  describe "#important" do
                    subject(:important) { note.important }

                    it { is_expected.to eq false }
                  end
                end

                describe "date of birth note" do
                  subject(:note) { claim_arg.notes.find_by("body LIKE ?", "[DQT Identity] - Date of birth not matched%") }

                  before { perform }

                  describe "#body" do
                    subject(:body) { note.body }

                    it do
                      is_expected.to eq(
                        <<~HTML
                          [DQT Identity] - Date of birth not matched:
                          <pre>
                            Claimant: <span class="dark-grey">"</span><span class="red">1990-08-23</span><span class="dark-grey">"</span>
                            DQT:      <span class="dark-grey">"</span><span class="green">1990-08-24</span><span class="dark-grey">"</span>
                          </pre>
                        HTML
                      )
                    end
                  end

                  describe "#label" do
                    subject(:label) { note.label }

                    it { is_expected.to eq("identity_confirmation") }
                  end

                  describe "#created_by" do
                    subject(:created_by) { note.created_by }

                    it { is_expected.to eq(nil) }
                  end

                  describe "#important" do
                    subject(:important) { note.important }

                    it { is_expected.to eq false }
                  end
                end
              end
            end

            context "without matching DQT record" do
              let(:data) { nil }

              it { is_expected.to be_an_instance_of(Task) }

              describe "identity confirmation task" do
                subject(:identity_confirmation_task) { claim_arg.tasks.find_by(name: "identity_confirmation") }

                before { perform }

                describe "#claim_verifier_match" do
                  subject(:claim_verifier_match) { identity_confirmation_task.claim_verifier_match }

                  it { is_expected.to eq "none" }
                end

                describe "#created_by" do
                  subject(:created_by) { identity_confirmation_task.created_by }

                  it { is_expected.to eq nil }
                end

                describe "#passed" do
                  subject(:passed) { identity_confirmation_task.passed }

                  it { is_expected.to eq nil }
                end

                describe "#manual" do
                  subject(:manual) { identity_confirmation_task.manual }

                  it { is_expected.to eq false }
                end
              end

              describe "note" do
                subject(:note) { claim_arg.notes.last }

                before { perform }

                describe "#body" do
                  subject(:body) { note.body }

                  it { is_expected.to eq("[DQT Identity] - Not matched") }
                end

                describe "#label" do
                  subject(:label) { note.label }

                  it { is_expected.to eq("identity_confirmation") }
                end

                describe "#created_by" do
                  subject(:created_by) { note.created_by }

                  it { is_expected.to eq(nil) }
                end
              end
            end
          end
        end
      end
    end
  end
end
