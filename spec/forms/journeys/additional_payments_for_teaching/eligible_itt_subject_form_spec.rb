require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::EligibleIttSubjectForm, type: :model do
  before do
    create(
      :journey_configuration,
      :additional_payments,
      current_academic_year: AcademicYear.new(2023)
    )
  end

  let(:journey) { Journeys::AdditionalPaymentsForTeaching }

  let(:answers) do
    build(
      :additional_payments_answers,
      attributes_for(
        :additional_payments_answers,
        trainee_teacher,
        itt_academic_year: itt_academic_year,
        current_school_id: create(:school, :early_career_payments_eligible).id
      )
    )
  end

  let(:journey_session) do
    create(:additional_payments_session, answers: answers)
  end

  let(:trainee_teacher) { nil }

  let(:itt_academic_year) { AcademicYear.new(2020) }

  let(:form) do
    described_class.new(
      journey: journey,
      journey_session: journey_session,
      params: params
    )
  end

  describe "validations" do
    subject { form }

    let(:params) { ActionController::Parameters.new }

    it do
      is_expected.to validate_inclusion_of(:eligible_itt_subject)
        .in_array(form.available_options)
        .with_message("Select a subject")
    end
  end

  describe "#available_subjects" do
    subject(:available_subjects) { form.available_subjects }

    let(:params) { ActionController::Parameters.new }

    context "when qualified teacher" do
      before do
        journey_session.answers.assign_attributes(
          nqt_in_academic_year_after_itt: true
        )
      end

      it do
        is_expected.to contain_exactly(
          "chemistry",
          "foreign_languages",
          "mathematics",
          "physics"
        )
      end
    end

    context "when trainee teacher" do
      context "when in ECP and LUP policy year range" do
        let(:trainee_teacher) { :trainee_teacher }

        it do
          is_expected.to contain_exactly(
            "chemistry",
            "computing",
            "mathematics",
            "physics"
          )
        end
      end
    end
  end

  describe "#show_hint_text?" do
    subject { form.show_hint_text? }

    let(:params) { ActionController::Parameters.new }

    context "when the claim is for a trainee teacher" do
      before do
        journey_session.answers.nqt_in_academic_year_after_itt = false
      end

      it { is_expected.to be false }
    end

    context "when the claim is for a qualified teacher" do
      before do
        journey_session.answers.nqt_in_academic_year_after_itt = false
      end

      context "when there is a single avaialble subject" do
        let(:itt_academic_year) { AcademicYear.new(2018) }

        before do
          Journeys::Configuration.last.update!(
            current_academic_year: AcademicYear.new(2019)
          )
        end

        it { is_expected.to be false }
      end

      context "when there are multiple available subjects" do
        before do
          journey_session.answers.nqt_in_academic_year_after_itt = true
        end

        it { is_expected.to be true }
      end
    end
  end

  describe "#chemistry_or_physics_available?" do
    subject { form.chemistry_or_physics_available? }

    let(:params) { ActionController::Parameters.new }

    let(:trainee_teacher) { :trainee_teacher }

    context "when the subject list contains chemistry" do
      before do
        allow(JourneySubjectEligibilityChecker).to(
          receive(:fixed_lup_subject_symbols).and_return([:chemistry])
        )
      end

      it { is_expected.to be true }
    end

    context "when the subject list contains physics" do
      before do
        allow(JourneySubjectEligibilityChecker).to(
          receive(:fixed_lup_subject_symbols).and_return([:physics])
        )
      end

      it { is_expected.to be true }
    end

    context "when the subject list does not contain chemistry or physics" do
      before do
        allow(JourneySubjectEligibilityChecker).to(
          receive(:fixed_lup_subject_symbols).and_return([:mathematics])
        )
      end

      it { is_expected.to be false }
    end
  end

  describe "#save" do
    context "when invalid" do
      let(:params) do
        ActionController::Parameters.new(
          claim: {
            eligible_itt_subject: "invalid"
          }
        )
      end

      it "returns false" do
        expect(form.save).to be(false)
      end
    end

    context "when valid" do
      let(:params) do
        ActionController::Parameters.new(
          claim: {
            eligible_itt_subject: "chemistry"
          }
        )
      end

      let(:answers) do
        build(
          :additional_payments_answers,
          attributes_for(
            :additional_payments_answers,
            trainee_teacher,
            itt_academic_year: itt_academic_year,
            teaching_subject_now: true,
            eligible_degree_subject: true
          )
        )
      end

      it "updates the answers" do
        expect { form.save }.to change { journey_session.reload.answers.eligible_itt_subject }.from(nil).to("chemistry")
      end

      it "resets dependent attributes" do
        expect {
          form.save
        }.to change { journey_session.reload.answers.teaching_subject_now }.from(true).to(nil)
          .and change { journey_session.reload.answers.eligible_degree_subject }.from(true).to(nil)
      end
    end

    context "when no change" do
      let(:params) do
        ActionController::Parameters.new(
          claim: {
            eligible_itt_subject: "chemistry"
          }
        )
      end

      let(:answers) do
        build(
          :additional_payments_answers,
          attributes_for(
            :additional_payments_answers,
            trainee_teacher,
            itt_academic_year: itt_academic_year,
            teaching_subject_now: true,
            eligible_itt_subject: params[:claim][:eligible_itt_subject]
          )
        )
      end

      it "does not reset dependent attributes" do
        expect {
          form.save
        }.to not_change { journey_session.reload.answers.teaching_subject_now }
          .and not_change { journey_session.reload.answers.eligible_degree_subject }
      end
    end

    context "when a change and teaching_subject_now from DQT" do
      let(:params) do
        ActionController::Parameters.new(
          claim: {
            eligible_itt_subject: "chemistry"
          }
        )
      end

      let(:answers) do
        build(
          :additional_payments_answers,
          attributes_for(
            :additional_payments_answers,
            trainee_teacher,
            itt_academic_year: itt_academic_year,
            teaching_subject_now: true,
            qualifications_details_check: true
          )
        )
      end

      it "does not reset dependent attributes" do
        expect { form.save }.to not_change { journey_session.reload.answers.teaching_subject_now }
          .and not_change { journey_session.reload.answers.eligible_degree_subject }
      end
    end
  end
end
