require "rails_helper"

RSpec.describe EligibleEyProvidersImporter do
  subject { described_class.new(file) }

  let(:file) { Tempfile.new }
  let(:correct_headers) { described_class.mandatory_headers.join(",") + "\n" }
  let(:local_authority) { create(:local_authority) }
  let(:file_upload) { create(:file_upload, :not_completed_processing, target_data_model: EligibleEyProvider.to_s) }

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
        subject.run(file_upload.id)

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
        subject.run(file_upload.id)

        expect(subject.errors).to be_empty
      end

      it "does not add any any records" do
        expect { subject.run(file_upload.id) }.not_to change { EligibleEyProvider.count }
      end

      context "when there are existing records" do
        before do
          create(:eligible_ey_provider, local_authority:)
          create(:eligible_ey_provider, :with_secondary_contact_email_address, local_authority:)
        end

        it "does not purge any records" do
          expect { subject.run(file_upload.id) }.not_to change { EligibleEyProvider.count }
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
        expect { subject.run(file_upload.id) }.to change { EligibleEyProvider.unscoped.count }.from(0).to(3)

        expect(EligibleEyProvider.count).to eq(0)
        file_upload.completed_processing!
        expect(EligibleEyProvider.count).to eq(3)
      end

      context "when there are existing records" do
        let!(:eligible_ey_provider1) { create(:eligible_ey_provider, local_authority:) }
        let!(:eligible_ey_provider2) { create(:eligible_ey_provider, :with_secondary_contact_email_address, local_authority:) }

        it "adds the new records with a new file_upload_id" do
          expect { subject.run(file_upload.id) }.to change { EligibleEyProvider.unscoped.count }.from(2).to(5)

          # Still returns the current providers
          expect(EligibleEyProvider.count).to eq(2)

          # FileUpload marked as processed, returns the 3 new providers
          file_upload.completed_processing!
          expect(EligibleEyProvider.count).to eq(3)

          # Can still get the previous providers
          expect(EligibleEyProvider.unscoped.where(file_upload: eligible_ey_provider1.file_upload)).to contain_exactly(eligible_ey_provider1, eligible_ey_provider2)
        end
      end
    end
  end
end
