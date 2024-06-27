require "rails_helper"

RSpec.describe Journeys::GetATeacherRelocationPayment::EmploymentDetailsForm, type: :model do
  let(:journey_session) { create(:get_a_teacher_relocation_payment_session) }

  let(:params) { ActionController::Parameters.new(claim: {}) }

  let(:form) do
    described_class.new(
      journey_session: journey_session,
      journey: Journeys::GetATeacherRelocationPayment,
      params: params
    )
  end

  describe "validations" do
    subject { form }

    it do
      is_expected.to(
        validate_presence_of(:school_headteacher_name)
        .with_message("Enter the headteacher's name")
      )
    end

    it do
      is_expected.to(
        validate_presence_of(:school_name)
        .with_message("Enter the school name")
      )
    end

    it do
      is_expected.to(
        validate_presence_of(:school_address_line_1)
        .with_message("Enter your school's address")
      )
    end

    it do
      is_expected.to(
        validate_presence_of(:school_city)
        .with_message("Enter your school's city")
      )
    end

    it do
      is_expected.not_to(
        allow_value(nil)
        .for(:school_postcode)
        .with_message("Enter a valid postcode (for example, BN1 1AA)")
      )
    end

    it do
      is_expected.not_to(
        allow_value("fff fff")
        .for(:school_postcode)
        .with_message("Enter a valid postcode (for example, BN1 1AA)")
      )
    end

    it { is_expected.to(allow_value("BN1 1AA").for(:school_postcode)) }
  end

  describe "#save" do
    let(:params) do
      ActionController::Parameters.new(claim: {
        school_headteacher_name: "Seymour Skinner",
        school_name: "Springfield Elementary School",
        school_address_line_1: "19",
        school_address_line_2: "Plympton Street",
        school_city: "Springfield",
        school_postcode: "TE57 1NG"
      })
    end

    it "updates the journey session" do
      expect { expect(form.save).to be(true) }.to(
        change { journey_session.reload.answers.school_headteacher_name }
        .to("Seymour Skinner")
        .and(
          change { journey_session.reload.answers.school_name }
          .to("Springfield Elementary School")
        ).and(
          change { journey_session.reload.answers.school_address_line_1 }
          .to("19")
        ).and(
          change { journey_session.reload.answers.school_address_line_2 }
          .to("Plympton Street")
        ).and(
          change { journey_session.reload.answers.school_city }
          .to("Springfield")
        ).and(
          change { journey_session.reload.answers.school_postcode }
          .to("TE57 1NG")
        )
      )
    end
  end
end
