require "rails_helper"

RSpec.describe "Admin page", type: :request do
	describe "GET /journey-components" do
		let(:journey) { Journeys.all.first }
		let(:slug) { journey.slug_sequence::SLUGS.first }

		it "renders the components page", :aggregate_failures do
			get journey_components_path

			expect(response).to be_successful
			expect(response.body).to include("Journey Components")
			expect(response.body).to include("Reused Components")
			expect(response.body).to include(claim_path(journey.routing_name, slug))
		end
	end

	describe "GET /" do
		it "loads the page" do
			get root_path

			expect(response).to be_successful
			expect(response.body).to include(journey_components_path)
			expect(response.body).to include(customer_journeys_path)
			expect(response.body).to include("href=\"/admin\"")
		end
	end

	describe "GET /customer-journeys" do
		it "loads the page with the main journey urls", :aggregate_failures do
			get customer_journeys_path

			expect(response).to be_successful
			expect(response.body).to include(Journeys::TargetedRetentionIncentivePayments.start_page_url)
			expect(response.body).to include(Journeys::TeacherStudentLoanReimbursement.start_page_url)
			expect(response.body).to include(Journeys::GetATeacherRelocationPayment.start_page_url)
			expect(response.body).to include(Journeys::FurtherEducationPayments.start_page_url)
			expect(response.body).to include(Journeys::EarlyYearsPayment::Provider::Start.start_page_url)
			expect(response.body).to include(Journeys::EarlyYearsPayment::Practitioner.start_page_url)
			expect(response.body).to include(Journeys::EarlyYearsTeachersFinancialIncentivePayments.start_page_url)
		end
	end

	describe "GET /journey-components/open" do
		let(:journey) { Journeys.all.first }
		let(:slug) { journey.slug_sequence::SLUGS.first }

		context "when unauthenticated" do
			it "redirects to the sign in page" do
				get open_component_path(journey: journey.routing_name, slug: slug)

				expect(response).to redirect_to(admin_sign_in_path)
			end
		end

		context "when authenticated" do
			let!(:sign_in) { sign_in_as_service_operator }

			it "redirects to the selected journey slug" do
				get open_component_path(journey: journey.routing_name, slug: slug)

				expect(response).to redirect_to(claim_path(journey.routing_name, slug, skip_landing_page: true))
			end

			it "renders the practitioner ineligible page" do
				get open_component_path(journey: Journeys::EarlyYearsPayment::Practitioner.routing_name, slug: "ineligible")
				follow_redirect!

				expect(response).to be_successful
				expect(response.body).to include("This claim reference is not correct")
			end

			it "renders a generic ineligible preview without raising an error" do
				get open_component_path(journey: Journeys::TeacherStudentLoanReimbursement.routing_name, slug: "ineligible")
				follow_redirect!

				expect(response).to be_successful
				expect(response.body).to include("You’re not eligible for this payment")
			end

			it "opens all journey component routes" do
				failures = []

				journey_component_routes.each do |route|
					journey_name = route[:journey]
					slug = route[:slug]
					expected_path = claim_path(journey_name, slug, skip_landing_page: true)

					get open_component_path(journey: journey_name, slug: slug)

					unless response.redirect? && response.location&.end_with?(expected_path)
						failures << "#{journey_name}/#{slug} did not redirect to #{expected_path} (got #{response.status}: #{response.location})"
					end
				end

				expect(failures).to be_empty, failures.join("\n")
			end

			it "renders all ineligible routes" do
				failures = []
				create(:school, :further_education, :closed)
				allow_any_instance_of(OrdnanceSurvey::Client).to receive_message_chain(:api, :search_places, :index).and_return([])

				journey_component_routes.select { |route| route[:slug] == "ineligible" }.each do |route|
					journey_name = route[:journey]

					begin
						get open_component_path(journey: journey_name, slug: "ineligible")
						follow_redirect!

						if response.status >= 500
							failures << "#{journey_name}/ineligible returned #{response.status}"
						end
					rescue StandardError => error
						failures << "#{journey_name}/ineligible raised #{error.class}: #{error.message}"
					end
				end

				expect(failures).to be_empty, failures.join("\n")
			end
		end
	end

	def journey_component_routes
		Journeys.all.sort_by(&:routing_name).flat_map do |journey|
			journey.slug_sequence.constants(false).flat_map do |constant_name|
				constant_value = journey.slug_sequence.const_get(constant_name)
				next [] unless constant_value.is_a?(Array)
				next [] unless constant_value.all? { |value| value.is_a?(String) }

				constant_value.map { |slug| {journey: journey.routing_name, slug: slug} }
			end
		end.uniq
	end
end
