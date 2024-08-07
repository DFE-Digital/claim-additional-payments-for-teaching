require "rails_helper"

RSpec.describe SignInForm do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) do
    build(
      :"#{journey::I18N_NAMESPACE}_session",
      answers: attributes_for(
        :"#{journey::I18N_NAMESPACE}_answers",
        :with_details_from_onelogin
      )
    )
  end

  let(:onelogin_user_info) do
    {email: "jo.bloggs@example.com", phone: nil}
  end

  let(:form) do
    described_class.new(
      journey: journey,
      journey_session: journey_session,
      params: params
    )
  end

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        # logged_in_with_tid: true
      }
    )
  end

  describe "#save" do
    before { form.save }

    it "keeps the details from onelogin_user_info" do
      expect(
        journey_session.answers.onelogin_user_info.symbolize_keys
      ).to(eq(onelogin_user_info))
    end

    it "keeps the first name" do
      expect(journey_session.answers.first_name).to eq "Jo"
    end

    it "keeps the surname" do
      expect(journey_session.answers.surname).to eq "Bloggs"
    end
  end
end
