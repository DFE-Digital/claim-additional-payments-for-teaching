require "rails_helper"

RSpec.describe EligibleEyProvidersImporter do
  subject { described_class.new(file) }

  let(:file) { Tempfile.new }
  let(:correct_headers) { described_class.mandatory_headers.join(",") + "\n" }
  let(:local_authority) { create(:local_authority) }

  def to_row(hash)
    [
      "\"#{hash[:nursery_name]}\"",
      hash[:urn],
      local_authority.code,
      "\"#{hash[:nursery_address]}\"",
      hash[:primary_key_contact_email_address],
      hash[:secondary_contact_email_address]
    ].join(",") + "\n"
  end

  describe "#run" do
    context "when incorrect headers" do
      before do
        file.write "incorrect,headers,here,here"
        file.close
      end

      it "has errors" do
        subject.run

        expect(subject.errors).to be_present
        expect(subject.errors).to include("The selected file is missing some expected columns: Nursery Name, EYURN / Ofsted URN, LA Code, Nursery Address, Primary Key Contact Email Address, Secondary Contact Email Address (Optional)")
      end
    end

    context "when csv has no rows" do
      before do
        file.write correct_headers
        file.close
      end

      it "has no errors" do
        subject.run

        expect(subject.errors).to be_empty
      end

      it "does not add any any records" do
        expect { subject.run }.not_to change { EligibleEyProvider.count }
      end

      context "when there are existing records" do
        before do
          create(:eligible_ey_provider, local_authority:)
          create(:eligible_ey_provider, local_authority:)
        end

        it "deletes existing records" do
          expect { subject.run }.to change { EligibleEyProvider.count }.to(0)
        end
      end
    end

    context "with valid data" do
      before do
        file.write correct_headers

        3.times do
          file.write to_row(attributes_for(:eligible_ey_provider))
        end

        file.close
      end

      it "imports new records" do
        expect { subject.run }.to change { EligibleEyProvider.count }.by(3)
      end

      context "when there are existing records" do
        before do
          create(:eligible_ey_provider, local_authority:)
          create(:eligible_ey_provider, local_authority:)
        end

        it "deletes them with new records" do
          expect { subject.run }.to change { EligibleEyProvider.count }.by(1)
        end
      end
    end
  end
end
