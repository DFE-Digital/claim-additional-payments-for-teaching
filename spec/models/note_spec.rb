require "rails_helper"

RSpec.describe Note, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:claim) }
    it { is_expected.to belong_to(:created_by).class_name("DfeSignIn::User").optional(true) }
  end

  describe "scopes" do
    describe ".automated" do
      it "runs a query with WHERE created_by_id IS NULL" do
        expect(described_class.automated.to_sql)
          .to eq described_class.all.where(created_by_id: nil).to_sql
      end
    end

    describe ".by_label" do
      it "runs a query with ORDER BY created_at DESC and WHERE label = <argument>" do
        expect(described_class.by_label("test").to_sql)
          .to eq described_class.all.order(created_at: :desc).where(label: "test").to_sql
      end
    end
  end
end
