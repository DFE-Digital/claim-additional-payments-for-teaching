require "rails_helper"

class Hash
  def replace_at_path(path, new_value)
    *steps, leaf = steps_from path

    # steps is empty in the "name" example, in that case, we are operating on
    # the root (self) hash, not a subhash
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
      if step.match?(/D/)
        step.to_i
      else
        step.to_sym
      end
    end
  end
end

RSpec.describe Dqt::Teacher do
  subject(:qualified_teaching_status) { described_class.new(qualified_teaching_status_response) }

  let(:qualified_teaching_status_response) do
    {
      trn: "1001000",
      ni_number: "JR501209A",
      name: "Fenton Laing",
      dob: "1987-08-22T00:00:00",
      active_alert: false,
      state: 0,
      state_name: "Active",
      qualified_teacher_status: {
        name: "Qualified teacher (trained)",
        qts_date: "2020-04-03T00:00:00",
        state: 0,
        state_name: "Active"
      },
      induction: {
        start_date: "2021-07-01T00:00:00Z",
        completion_date: "2021-07-05T00:00:00Z",
        status: "Pass",
        state: 0,
        state_name: "Active"
      },
      initial_teacher_training: {
        programme_start_date: "2021-06-27T00:00:00Z",
        programme_end_date: "2021-07-04T00:00:00Z",
        programme_type: "Overseas Trained Teacher Programme",
        result: "Pass",
        subject1: "G100",
        subject2: "NULL",
        subject3: "NULL",
        qualification: "Graduate Diploma",
        state: 0,
        state_name: "Active"
      }
    }
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
      before { qualified_teaching_status_response.replace_at_path(response_keys, "1944-10-22") }

      it "returns String" do
        expect(subject).to eq Date.new(1944, 10, 22)
      end
    end

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

      it "reports error to Rollbar" do
        allow(Rollbar).to receive(:error)

        subject

        expect(Rollbar).to have_received(:error)
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

  shared_examples "boolean reader" do |response_keys|
    context "when response value true" do
      before { qualified_teaching_status_response.replace_at_path(response_keys, true) }

      it "returns true" do
        expect(subject).to equal true
      end
    end

    context "when response value false" do
      before { qualified_teaching_status_response.replace_at_path(response_keys, false) }

      it "returns false" do
        expect(subject).to equal false
      end
    end

    [
      "true",
      "TRUE",
      "True",
      "TrUe",
      " true "
    ].each do |true_string|
      context "when response value true as String (eg '#{true_string}')" do
        before { qualified_teaching_status_response.replace_at_path(response_keys, true_string) }

        it "returns true" do
          expect(subject).to equal true
        end
      end
    end

    [
      "false",
      "FALSE",
      "False",
      "FaLsE",
      " false "
    ].each do |false_string|
      context "when response value false as String (eg '#{false_string}')" do
        before { qualified_teaching_status_response.replace_at_path(response_keys, false_string) }

        it "returns false" do
          expect(subject).to equal false
        end
      end
    end

    context "when response value nil" do
      before { qualified_teaching_status_response.replace_at_path(response_keys, nil) }

      it "returns nil" do
        expect(subject).to equal nil
      end
    end

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

    it_behaves_like "string reader", "name"

    [
      {name: "Fenton Laing", first_name: "Fenton"},
      {name: "Fenton La La Laing", first_name: "Fenton"},
      {name: " Fenton La Laing ", first_name: "Fenton"},
      {name: "fenton laing", first_name: "fenton"}
    ].each do |scenario|
      context "when response name '#{scenario[:name]}' String" do
        before { qualified_teaching_status_response[:name] = scenario[:name] }

        it "returns '#{scenario[:first_name]}'" do
          expect(first_name).to eq scenario[:first_name]
        end
      end
    end
  end

  describe "#surname" do
    subject(:surname) { qualified_teaching_status.surname }

    it_behaves_like "string reader", "name"

    [
      {name: "Fenton Laing", surname: "Laing"},
      {name: "Fenton La La Laing", surname: "Laing"},
      {name: " Fenton La Laing ", surname: "Laing"},
      {name: "fenton laing", surname: "laing"}
    ].each do |scenario|
      context "when response name String (eg '#{scenario[:name]}')" do
        before { qualified_teaching_status_response[:name] = scenario[:name] }

        it "returns '#{scenario[:surname]}'" do
          expect(surname).to eq scenario[:surname]
        end
      end
    end
  end

  describe "#date_of_birth" do
    subject(:date_of_birth) { qualified_teaching_status.date_of_birth }

    it_behaves_like "date reader", "dob"
  end

  describe "#degree_codes" do
    subject(:degree_codes) { qualified_teaching_status.degree_codes }

    it "returns Array" do
      expect(degree_codes).to eq []
    end
  end

  describe "#national_insurance_number" do
    subject(:national_insurance_number) { qualified_teaching_status.national_insurance_number }

    it_behaves_like "string reader", "ni_number"
  end

  describe "#qts_award_date" do
    subject(:qts_award_date) { qualified_teaching_status.qts_award_date }

    it_behaves_like "date reader", "qualified_teacher_status/qts_date"
  end

  describe "#itt_subject_codes" do
    subject(:itt_subject_codes) { qualified_teaching_status.itt_subject_codes }

    it_behaves_like(
      "string reader",
      (1..3).map { |n| "initial_teacher_training/subject#{n}" }
    )
  end

  describe "#active_alert?" do
    subject(:active_alert?) { qualified_teaching_status.active_alert? }

    it_behaves_like "boolean reader", "active_alert"
  end

  describe "#qualification_name" do
    subject(:qualification_name) { qualified_teaching_status.qualification_name }

    it_behaves_like "string reader", "initial_teacher_training/qualification"
  end

  describe "#itt_start_date" do
    subject(:itt_start_date) { qualified_teaching_status.itt_start_date }

    it_behaves_like "date reader", "initial_teacher_training/programme_start_date"
  end
end
