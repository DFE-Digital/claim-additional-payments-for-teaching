require "rails_helper"

RSpec.describe "Admin service access links" do
  before do
    create(:journey_configuration, :further_education_payments)
  end

  let(:journey) { Journeys::FurtherEducationPayments.routing_name }
  let(:service_access_code) do
    Journeys::ServiceAccessCode.create!(journey: Journeys::FurtherEducationPayments)
  end

  context "when the admin_permissions feature flag is disabled" do
    context "when signed in as a service operator" do
      it "does not allow viewing or creating links, even with a grant" do
        operator = sign_in_as_service_operator
        create(:admin_permissions_grant, user: operator, permission: "service_access_links.show")
        create(:admin_permissions_grant, user: operator, permission: "service_access_links.create")

        get admin_service_access_link_path(service_access_code)
        expect(response).to have_http_status(:unauthorized)

        expect { post admin_service_access_links_path(journey: journey) }
          .not_to change(Journeys::ServiceAccessCode, :count)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a service admin" do
      before { sign_in_as_service_admin }

      it "allows viewing and creating links without any grants" do
        get admin_service_access_link_path(service_access_code)
        expect(response).to have_http_status(:ok)

        expect { post admin_service_access_links_path(journey: journey) }
          .to change(Journeys::ServiceAccessCode, :count).by(1)
      end
    end
  end

  context "when the admin_permissions feature flag is enabled" do
    before { FeatureFlag.enable!(:admin_permissions) }

    let(:admin) { create(:dfe_signin_user, :service_operator) }

    before { sign_in_with_admin(admin) }

    context "when the user has no grants" do
      it "does not allow viewing or creating links" do
        get admin_service_access_link_path(service_access_code)
        expect(response).to have_http_status(:forbidden)

        expect { post admin_service_access_links_path(journey: journey) }
          .not_to change(Journeys::ServiceAccessCode, :count)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the user is a service admin but has no grants" do
      let(:admin) { create(:dfe_signin_user, :service_admin) }

      it "does not allow creating links" do
        expect { post admin_service_access_links_path(journey: journey) }
          .not_to change(Journeys::ServiceAccessCode, :count)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the user has been granted service_access_links.show" do
      before do
        create(:admin_permissions_grant, user: admin, permission: "service_access_links.show")
      end

      it "allows viewing a link but not creating one" do
        get admin_service_access_link_path(service_access_code)
        expect(response).to have_http_status(:ok)

        post admin_service_access_links_path(journey: journey)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the user has been granted service_access_links.create" do
      before do
        create(:admin_permissions_grant, user: admin, permission: "service_access_links.create")
      end

      it "allows creating a link" do
        expect { post admin_service_access_links_path(journey: journey) }
          .to change(Journeys::ServiceAccessCode, :count).by(1)
      end
    end

    context "when the user's grant has been revoked" do
      before do
        create(
          :admin_permissions_grant,
          :revoked,
          user: admin,
          permission: "service_access_links.create"
        )
      end

      it "does not allow creating a link" do
        post admin_service_access_links_path(journey: journey)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
