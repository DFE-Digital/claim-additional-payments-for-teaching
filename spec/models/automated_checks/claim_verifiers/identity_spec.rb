require "rails_helper"

module AutomatedChecks
  module ClaimVerifiers
    RSpec.describe Identity do
      subject(:identity) { described_class.new(**identity_args) }

      before do
        if data.nil?
          body = <<~JSON
            {
              "data": null,
              "message": "No records found."
            }
          JSON

          status = 404
        else
          body = <<~JSON
            {
              "data": [
                {
                  "trn": "#{data[:teacher_reference_number]}",
                  "name": "#{data[:name]}",
                  "doB": "#{data[:date_of_birth] || Date.today}",
                  "niNumber": "#{data[:national_insurance_number]}",
                  "qtsAwardDate": "#{data[:qts_award_date] || Date.today}",
                  "ittSubject1Code": "#{data.dig(:itt_subject_codes, 0)}",
                  "ittSubject2Code": "#{data.dig(:itt_subject_codes, 1)}",
                  "ittSubject3Code": "#{data.dig(:itt_subject_codes, 2)}",
                  "activeAlert": #{data[:active_alert] || false},
                  "qualificationName": "#{data[:qualification_name] || "BA"}",
                  "ittStartDate": "#{data[:itt_start_date] || Date.today}"
                }
              ],
              "message": null
            }
          JSON

          status = 200
        end

        stub_request(:get, "#{ENV["DQT_CLIENT_HOST"]}:#{ENV["DQT_CLIENT_PORT"]}/api/qualified-teachers/qualified-teaching-status").with(
          query: WebMock::API.hash_including(
            {
              trn: "1234567",
              ni: "QQ100000C"
            }
          )
        ).to_return(body: body, status: status)
      end

      let(:claim_arg) do
        claim = create(
          :claim,
          :submitted,
          date_of_birth: Date.new(1990, 8, 23),
          first_name: "Fred",
          national_insurance_number: "QQ100000C",
          reference: "AB123456",
          surname: "ELIGIBLE",
          teacher_reference_number: "1234567",
          policy: policy
        )

        policy_underscored = policy.to_s.underscore

        claim.eligibility.update!(
          attributes_for(
            :"#{policy_underscored}_eligibility",
            :eligible
          )
        )

        claim
      end

      let(:identity_args) do
        {
          claim: claim_arg,
          dqt_teacher_status: Dqt::Client.new.api.qualified_teaching_status.show(
            params: {
              teacher_reference_number: claim_arg.teacher_reference_number,
              national_insurance_number: claim_arg.national_insurance_number
            }
          )
        }
      end

      describe "#perform" do
        subject(:perform) { identity.perform }

        [
          EarlyCareerPayments,
          MathsAndPhysics,
          StudentLoans
        ].each do |policy|
          context "with policy #{policy}" do
            let(:policy) { policy }

            context "with matching DQT identity" do
              let(:data) do
                {
                  date_of_birth: Date.new(1990, 8, 23),
                  name: "Fred ELIGIBLE",
                  national_insurance_number: "QQ100000C",
                  teacher_reference_number: "1234567"
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

              context "except national insurance number" do
                let(:data) do
                  {
                    date_of_birth: claim_arg.date_of_birth,
                    name: "#{claim_arg.first_name} #{claim_arg.surname}",
                    national_insurance_number: "QQ100000B",
                    teacher_reference_number: claim_arg.teacher_reference_number
                  }
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

                    it do
                      is_expected.to eq(
                        <<~HTML
                          National Insurance number not matched:
                          <pre>
                            Claimant: <span class="dark-grey">"</span><span class="red">QQ100000C</span><span class="dark-grey">"</span>
                            DQT:      <span class="dark-grey">"</span><span class="green">QQ100000B</span><span class="dark-grey">"</span>
                          </pre>
                        HTML
                      )
                    end
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

              context "except matching teacher reference number" do
                let(:data) do
                  {
                    date_of_birth: claim_arg.date_of_birth,
                    name: "#{claim_arg.first_name} #{claim_arg.surname}",
                    national_insurance_number: claim_arg.national_insurance_number,
                    teacher_reference_number: "7654321"
                  }
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

                    it do
                      is_expected.to eq(
                        <<~HTML
                          Teacher reference number not matched:
                          <pre>
                            Claimant: <span class="dark-grey">"</span><span class="red">1234567</span><span class="dark-grey">"</span>
                            DQT:      <span class="dark-grey">"</span><span class="green">7654321</span><span class="dark-grey">"</span>
                          </pre>
                        HTML
                      )
                    end
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

              context "except matching first name" do
                let(:data) do
                  {
                    date_of_birth: claim_arg.date_of_birth,
                    name: "Except #{claim_arg.surname}",
                    national_insurance_number: claim_arg.national_insurance_number,
                    teacher_reference_number: claim_arg.teacher_reference_number
                  }
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

                    it do
                      is_expected.to eq(
                        <<~HTML
                          First name or surname not matched:
                          <pre>
                            Claimant: <span class="dark-grey">"</span><span class="red">Fred ELIGIBLE</span><span class="dark-grey">"</span>
                            DQT:      <span class="dark-grey">"</span><span class="green">Except ELIGIBLE</span><span class="dark-grey">"</span>
                          </pre>
                        HTML
                      )
                    end
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

              context "except matching surname" do
                let(:data) do
                  {
                    date_of_birth: claim_arg.date_of_birth,
                    name: "#{claim_arg.first_name} Except",
                    national_insurance_number: claim_arg.national_insurance_number,
                    teacher_reference_number: claim_arg.teacher_reference_number
                  }
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

                    it do
                      is_expected.to eq(
                        <<~HTML
                          First name or surname not matched:
                          <pre>
                            Claimant: <span class="dark-grey">"</span><span class="red">Fred ELIGIBLE</span><span class="dark-grey">"</span>
                            DQT:      <span class="dark-grey">"</span><span class="green">Fred Except</span><span class="dark-grey">"</span>
                          </pre>
                        HTML
                      )
                    end
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

              context "with middle names" do
                let(:data) do
                  {
                    date_of_birth: claim_arg.date_of_birth,
                    name: "#{claim_arg.first_name} Middle Names #{claim_arg.surname}",
                    national_insurance_number: claim_arg.national_insurance_number,
                    teacher_reference_number: claim_arg.teacher_reference_number
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
              end

              context "except matching date of birth" do
                let(:data) do
                  {
                    date_of_birth: claim_arg.date_of_birth + 1.day,
                    name: "#{claim_arg.first_name} #{claim_arg.surname}",
                    national_insurance_number: claim_arg.national_insurance_number,
                    teacher_reference_number: claim_arg.teacher_reference_number
                  }
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

                    it do
                      is_expected.to eq(
                        <<~HTML
                          Date of birth not matched:
                          <pre>
                            Claimant: <span class="dark-grey">"</span><span class="red">1990-08-23</span><span class="dark-grey">"</span>
                            DQT:      <span class="dark-grey">"</span><span class="green">1990-08-24T00:00:00+00:00</span><span class="dark-grey">"</span>
                          </pre>
                        HTML
                      )
                    end
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
                    national_insurance_number: "QQ100000C",
                    reference: "AB123456",
                    surname: "ELIGIBLE",
                    tasks: [build(:task, name: :identity_confirmation)],
                    teacher_reference_number: "1234567"
                  )
                end

                it { is_expected.to eq(nil) }

                describe "identity confirmation task" do
                  subject(:identity_confirmation_task) { claim_arg.tasks.find_by(name: "identity_confirmation") }

                  before { perform }

                  describe "#claim_verifier_match" do
                    subject(:claim_verifier_match) { identity_confirmation_task.claim_verifier_match }

                    it { is_expected.to eq nil }
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
                  {
                    active_alert: true,
                    date_of_birth: claim_arg.date_of_birth,
                    name: "#{claim_arg.first_name} #{claim_arg.surname}",
                    national_insurance_number: claim_arg.national_insurance_number,
                    teacher_reference_number: claim_arg.teacher_reference_number
                  }
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

              context "when claim field have extra whitespace" do
                let(:claim_arg) do
                  claim = create(
                    :claim,
                    :submitted,
                    date_of_birth: Date.new(1990, 8, 23),
                    first_name: "   Fred",
                    national_insurance_number: " QQ100000C ",
                    reference: "AB123456",
                    surname: "ELIGIBLE ",
                    teacher_reference_number: " 1234567   ",
                    policy: MathsAndPhysics
                  )

                  claim.eligibility.update!(
                    attributes_for(
                      :maths_and_physics_eligibility,
                      :eligible,
                      initial_teacher_training_subject: :maths
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

              context "except multiple matches" do
                let(:data) do
                  {
                    date_of_birth: claim_arg.date_of_birth + 1.day,
                    name: "Except #{claim_arg.surname}",
                    national_insurance_number: claim_arg.national_insurance_number,
                    teacher_reference_number: claim_arg.teacher_reference_number
                  }
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
                  subject(:note) { claim_arg.notes.find_by("body LIKE ?", "First name or surname not matched%") }

                  before { perform }

                  describe "#body" do
                    subject(:body) { note.body }

                    it do
                      is_expected.to eq(
                        <<~HTML
                          First name or surname not matched:
                          <pre>
                            Claimant: <span class="dark-grey">"</span><span class="red">Fred ELIGIBLE</span><span class="dark-grey">"</span>
                            DQT:      <span class="dark-grey">"</span><span class="green">Except ELIGIBLE</span><span class="dark-grey">"</span>
                          </pre>
                        HTML
                      )
                    end
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
                  subject(:note) { claim_arg.notes.find_by("body LIKE ?", "Date of birth not matched%") }

                  before { perform }

                  describe "#body" do
                    subject(:body) { note.body }

                    it do
                      is_expected.to eq(
                        <<~HTML
                          Date of birth not matched:
                          <pre>
                            Claimant: <span class="dark-grey">"</span><span class="red">1990-08-23</span><span class="dark-grey">"</span>
                            DQT:      <span class="dark-grey">"</span><span class="green">1990-08-24T00:00:00+00:00</span><span class="dark-grey">"</span>
                          </pre>
                        HTML
                      )
                    end
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

            context "without matching DQT identity" do
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

                  it { is_expected.to eq("Not matched") }
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
