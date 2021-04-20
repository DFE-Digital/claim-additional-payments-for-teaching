require "rails_helper"

RSpec.describe EarlyCareerPayments, type: :model do
  let(:policy_configuration) { policy_configurations(:early_career_payments) }

  describe ".routing_name" do
    it "returns 'early-career-payments'" do
      expect(subject.routing_name).to eq "early-career-payments"
    end
  end

  describe ".start_page_url" do
    context "Production environment" do
      it "returns a url containing 'https://www.gov.uk/guidance/'" do
        allow(Rails).to receive(:env) { "production".inquiry }
        expect(subject.start_page_url).to include("https://www.gov.uk/guidance/")
      end
    end

    context "Non-Production environments" do
      it "returns a url containing '/early-career-payments/claim'" do
        expect(subject.start_page_url).to include("/early-career-payments/claim")
      end
    end
  end

  describe ".feedback_url" do
    it "returns a 'docs.google.com/forms/<slug>/viewform' url" do
      # TODO get proper feedback URL - ECP-509
      expect(subject.feedback_url).to include("https://docs.google.com/forms/TO-BE-REPLACED-by-response-to-ECP-509/viewform")
    end
  end

  describe ".short_name" do
    it "returns the 'policy_short_name' translation" do
      expect(subject.short_name).to eql "Early Career Payments"
    end
  end

  describe ".locale_key" do
    it "returns 'routing_name' in the correct format to match the 'root key' in the translation file" do
      expect(subject.locale_key).to eql subject.routing_name.underscore
    end
  end

  describe ".notify_reply_to_id" do
    let(:ecp_notify_reply_to_id) do
      "3f85a1f7-9400-4b48-9a31-eaa643d6b977"
    end
    it "returns the notify_reply_to_id" do
      # TODO replace with valid ID - ECP-515
      expect(subject.notify_reply_to_id).to eql ecp_notify_reply_to_id
    end
  end

  describe ".eligibility_page_url" do
    it "returns a link to the guidance page for eligibility url" do
      expect(subject.eligibility_page_url).to include("https://www.gov.uk/publications/TO-BE-REPLACED-by-response-to-ECP-518")
    end
  end

  describe ".first_eligible_qts_award_year" do
    let(:policy_configuration) { policy_configurations(:early_career_payments) }

    it "can return the AcademicYear based on a passed-in academic year" do
      expect(EarlyCareerPayments.first_eligible_qts_award_year(AcademicYear.new(2024))).to eq AcademicYear.new(2021)
    end
  end
end
