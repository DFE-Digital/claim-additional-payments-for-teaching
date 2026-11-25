require "rails_helper"

RSpec.describe Admin::Permissions::Enforcement do
  describe ".permissions" do
    let(:parent) do
      Class.new(ActionController::Base) do
        include Admin::Permissions::Enforcement

        permissions index: "parent.index"
      end
    end

    let(:child) do
      Class.new(parent) do
        permissions show: "child.show", index: "child.index"
      end
    end

    it "stores the map with string keys" do
      expect(parent.action_permissions).to eq("index" => "parent.index")
    end

    it "lets subclasses add and override permissions" do
      expect(child.action_permissions).to eq(
        "index" => "child.index",
        "show" => "child.show"
      )
    end

    it "does not leak subclass permissions into the parent" do
      child

      expect(parent.action_permissions).to eq("index" => "parent.index")
    end

    it "merges repeated declarations" do
      parent.permissions create: "parent.create"

      expect(parent.action_permissions).to eq(
        "index" => "parent.index",
        "create" => "parent.create"
      )
    end
  end
end
