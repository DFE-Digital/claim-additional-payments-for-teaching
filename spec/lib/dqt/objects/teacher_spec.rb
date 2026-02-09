require "rails_helper"

class Hash
  def replace_at_path(path, new_value)
    *steps, leaf = steps_from path

    # steps is empty in the "name" example, in that case, we are operating on
    # the root (self) hash, not a subhash
    steps.map! { |s| /\A\d+\z/.match?(s.to_s) ? s.to_s.to_i : s }
    hash = steps.empty? ? self : dig(*steps)
    # note that `hash` here doesn't _have_ to be a Hash, but it needs to
    # respond to `[]=`
    hash[leaf] = new_value
  end

  private

  # the example hash uses symbols as the keys, so we'll convert each step in
  # the path to symbols. If a step doesn't contain a non-digit character,
  # we'll convert it to an integer to be treated as the index into an array
  def steps_from path
    path.split("/").map do |step|
      if step.match?(/\d/)
        step.to_i
      else
        step.to_sym
      end
    end
  end
end

RSpec.describe Dqt::Teacher do
  subject(:qualified_teaching_status) { described_class.new(qualified_teaching_status_response) }

  let(:teacher_reference_number_str) { "1001000" }
  let(:date_of_birth_str) { "1987-08-22" }

  let(:alerts) { [] }

  let(:training_subjects) do
    [
      {
        name: "Mathematics",
        reference: "G100"
      }
    ]
  end

  let(:training_subjects_multiple) do
    [
      {
        name: "Chemistry",
        reference: "F100"
      },
      {
        name: "Physics",
        reference: "F300"
      }
    ]
  end

  let(:routes) do
    [
      {
        holdsFrom: "2022-01-09",
        trainingSubjects: training_subjects,
        trainingStartDate: "2021-06-27",
        trainingEndDate: "2021-07-04",
        routeToProfessionalStatusType: {
          name: "Graduate Diploma"
        }
      }
    ]
  end

  let(:routes_multiple) do
    [
      {
        holdsFrom: "2022-01-09",
        trainingSubjects: training_subjects,
        trainingStartDate: "2021-06-27",
        trainingEndDate: "2021-07-04",
        routeToProfessionalStatusType: {
          name: "Graduate Diploma"
        }
      },
      {
        holdsFrom: "2022-01-09",
        trainingSubjects: training_subjects_multiple,
        trainingStartDate: "2021-06-27",
        trainingEndDate: "2021-07-04",
        routeToProfessionalStatusType: {
          name: "Graduate Diploma"
        }
      }
    ]
  end

  let(:qualified_teaching_status_response) do
    {
      qts: {
        holdsFrom: "2020-04-03"
      },
      trn: teacher_reference_number_str,
      alerts: alerts,
      lastName: "Laing",
      firstName: "Fenton",
      induction: {
        status: "Passed",
        startDate: "2021-07-01",
        completedDate: "2021-07-05"
      },
      dateOfBirth: date_of_birth_str,
      nationalInsuranceNumber: "JR501209A",
      routesToProfessionalStatuses: routes
    }
  end

  let(:dqt_higher_education_qualification_mathematics) do
    create(
      :dqt_higher_education_qualification,
      teacher_reference_number: teacher_reference_number_str,
      date_of_birth: Date.parse(date_of_birth_str),
      subject_code: "100403",
      description: "mathematics"
    )
  end

  let(:dqt_higher_education_qualification_accounting) do
    create(
      :dqt_higher_education_qualification,
      teacher_reference_number: teacher_reference_number_str,
      date_of_birth: Date.parse(date_of_birth_str),
      subject_code: "100105",
      description: "accounting"
    )
  end

  before do
    dqt_higher_education_qualification_mathematics
    dqt_higher_education_qualification_accounting
  end

  shared_examples "string reader" do |response_keys|
    let(:collection) { response_keys.respond_to?(:each) }
    let(:response_keys) { response_keys }

    def expectation(expectation)
      collection ? Array.new(response_keys.length, expectation).compact : expectation
    end

    def response(response)
      response_func = ->(response_key) { qualified_teaching_status_response.replace_at_path(response_key, response) }

      if collection
        response_keys.each do |response_key|
          response_func.call(response_key)
        end
      else
        response_func.call(response_keys)
      end
    end

    context "when response values String" do
      before { response("AString") }

      it "returns String" do
        expect(subject).to eql expectation("AString")
      end
    end

    context "when response value String as Integer" do
      before { response(12345) }

      it "returns String" do
        expect(subject).to eql expectation("12345")
      end
    end

    context "when response value nil" do
      before { response(nil) }

      it "returns nil" do
        expect(subject).to eql expectation(nil)
      end
    end

    # NOTE: not sure the v3 API has these issues anymore, but leaving for now
    [
      "nil",
      "NIL",
      "Nil",
      "NiL",
      " nil ",
      "null",
      "NULL",
      "Null",
      "NuLl",
      " null "
    ].each do |nil_string|
      context "when response value nil (eg '#{nil_string}') as String" do
        before { response(nil_string) }

        it "returns nil" do
          expect(subject).to eql expectation(nil)
        end
      end
    end
  end

  shared_examples "date reader" do |response_keys|
    context "when response value Date as String" do
      before {
        qualified_teaching_status_response.replace_at_path(response_keys, "1944-10-22")
      }

      it "returns String" do
        expect(subject).to eq Date.new(1944, 10, 22)
      end
    end

    # NOTE: v3 API should be just YYYY-MM-DD, but leaving here for now
    [
      "1944-10-22T00:00:00",
      "1944-10-22T00:00:00+00:00",
      "1944-10-22T00:00:00.1440844Z",
      "1944-10-22T00:00:00.1440844-00:00"
    ].each do |date_time|
      context "when response value DateTime as String (eg '#{date_time}')" do
        before { qualified_teaching_status_response.replace_at_path(response_keys, date_time) }

        it "returns Date" do
          expect(subject).to eq Date.new(1944, 10, 22)
        end
      end
    end

    context "when response value Time as Integer" do
      before { qualified_teaching_status_response.replace_at_path(response_keys, -795052800) }

      it "returns Date" do
        expect(subject).to eq Date.new(1944, 10, 22)
      end
    end

    context "when response value Time as String" do
      before { qualified_teaching_status_response.replace_at_path(response_keys, "-795052800") }

      it "returns Date" do
        expect(subject).to eq Date.new(1944, 10, 22)
      end
    end

    context "when response value non Date as String" do
      before { qualified_teaching_status_response.replace_at_path(response_keys, "x") }

      it "reports error to Sentry" do
        allow(Sentry).to receive(:capture_exception)

        subject

        expect(Sentry).to have_received(:capture_exception)
      end

      it "returns nil" do
        expect(subject).to equal nil
      end
    end

    context "when response value nil" do
      before { qualified_teaching_status_response.replace_at_path(response_keys, nil) }

      it "returns nil" do
        expect(subject).to equal nil
      end
    end

    # NOTE: not sure the v3 API has these issues anymore, but leaving for now
    [
      "nil",
      "NIL",
      "Nil",
      "NiL",
      " nil ",
      "null",
      "NULL",
      "Null",
      "NuLl",
      " null "
    ].each do |nil_string|
      context "when response value nil (eg '#{nil_string}') as String" do
        before { qualified_teaching_status_response.replace_at_path(response_keys, nil_string) }

        it "returns nil" do
          expect(subject).to equal nil
        end
      end
    end
  end

  describe "#teacher_reference_number" do
    subject(:teacher_reference_number) { qualified_teaching_status.teacher_reference_number }

    it_behaves_like "string reader", "trn"
  end

  describe "#first_name" do
    subject(:first_name) { qualified_teaching_status.first_name }

    it_behaves_like "string reader", "firstName"
  end

  describe "#surname" do
    subject(:surname) { qualified_teaching_status.surname }

    it_behaves_like "string reader", "lastName"
  end

  describe "#induction_start_date" do
    subject(:induction_start_date) { qualified_teaching_status.induction_start_date }

    it_behaves_like "date reader", "induction/startDate"
  end

  describe "#induction_completion_date" do
    subject(:induction_completion_date) { qualified_teaching_status.induction_completion_date }

    it_behaves_like "date reader", "induction/completedDate"
  end

  describe "#induction_status" do
    subject(:induction_status) { qualified_teaching_status.induction_status }

    it_behaves_like "string reader", "induction/status"
  end

  describe "#date_of_birth" do
    subject(:date_of_birth) { qualified_teaching_status.date_of_birth }

    it_behaves_like "date reader", "dateOfBirth"
  end

  describe "#degree_codes" do
    subject(:degree_codes) { qualified_teaching_status.degree_codes }

    specify { expect(degree_codes).to contain_exactly("100403", "100105") }
  end

  describe "#national_insurance_number" do
    subject(:national_insurance_number) { qualified_teaching_status.national_insurance_number }

    it_behaves_like "string reader", "nationalInsuranceNumber"
  end

  describe "#qts_award_date" do
    subject(:qts_award_date) { qualified_teaching_status.qts_award_date }

    it_behaves_like "date reader", "qts/holdsFrom"
  end

  describe "#itt_subjects" do
    subject(:itt_subjects) { qualified_teaching_status.itt_subjects }

    context "single itt with single code" do
      it { is_expected.to contain_exactly("Mathematics") }
    end

    context "single itt multiple codes" do
      let(:training_subjects) { training_subjects_multiple }

      it { is_expected.to contain_exactly("Chemistry", "Physics") }
    end

    context "multiple itts" do
      let(:routes) { routes_multiple }

      it { is_expected.to contain_exactly("Mathematics", "Chemistry", "Physics") }
    end
  end

  describe "#itt_subject_codes" do
    subject(:itt_subject_codes) { qualified_teaching_status.itt_subject_codes }

    context "single itt with single code" do
      it { is_expected.to contain_exactly("G100") }
    end

    context "single itt multiple codes" do
      let(:training_subjects) { training_subjects_multiple }

      it { is_expected.to contain_exactly("F100", "F300") }
    end

    context "multiple itts" do
      let(:routes) { routes_multiple }

      it { is_expected.to contain_exactly("G100", "F300", "F100") }
    end
  end

  describe "#active_alert?" do
    subject(:active_alert?) { qualified_teaching_status.active_alert? }

    context "no alerts" do
      it { is_expected.to be false }
    end

    context "alert without end date" do
      let(:alerts) do
        [
          {
            startDate: "2026-02-03",
            endDate: nil
          }
        ]
      end

      it { is_expected.to be true }
    end
    context "alert with end date" do
      let(:alerts) do
        [
          {
            startDate: "2026-01-01",
            endDate: "2026-01-31"
          }
        ]
      end

      it { is_expected.to be false }
    end
  end

  describe "#qualification_name" do
    subject(:qualification_name) { qualified_teaching_status.qualification_name }

    it_behaves_like "string reader", "routesToProfessionalStatuses/0/routeToProfessionalStatusType/name"
  end

  describe "#itt_start_date" do
    subject(:itt_start_date) { qualified_teaching_status.itt_start_date }

    it_behaves_like "date reader", "routesToProfessionalStatuses/0/trainingStartDate"
  end

  describe "#degree_names" do
    subject(:degree_names) { qualified_teaching_status.degree_names }

    specify { expect(degree_names).to contain_exactly("mathematics", "accounting") }
  end
end
