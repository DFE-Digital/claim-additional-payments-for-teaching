require "rails_helper"

class TestDummyController < BasePublicController
  include PartOfClaimJourney
  include FormSubmittable

  # Overriding template for current slug to bypass view search
  def render_template_for_current_slug
    render plain: "Rendered template for current slug: #{current_slug}"
  end

  skip_before_action :send_unstarted_claimants_to_the_start

  def slugs
    %w[first-slug second-slug]
  end

  def next_slug
    slugs[current_slug_index + 1]
  end

  def current_slug
    slugs[current_slug_index]
  end

  def current_slug_index
    slugs.index(params[:slug]) || 0
  end
end

class TestDummyForm < Form
  def save
  end
end

RSpec.describe FormSubmittable, type: :request do
  before do
    Rails.application.routes.draw do
      scope path: ":journey", constraints: {journey: "additional-payments"} do
        get "/claim", to: "test_dummy#new"
        get "/:slug", as: :test_dummy, to: "test_dummy#show"
        post "/:slug", to: "test_dummy#create", as: :test_dummies
        patch "/:slug", to: "test_dummy#update"
      end
    end
  end

  after { Rails.application.reload_routes! }

  before { create(:journey_configuration, :additional_payments) }

  shared_context :define_filter do |filter_name|
    before { define_filter(filter_name) }
    after { remove_filter(filter_name) }

    def define_filter(filter_name)
      TestDummyController.class_eval do
        define_method(filter_name) do
          render plain: "Triggered: `#{filter_name}` filter"
        end
      end
    end

    def remove_filter(filter_name)
      TestDummyController.class_eval do
        remove_method(filter_name) if method_defined?(filter_name)
      end
    end
  end

  describe "GET #new" do
    it "redirects to the first slug" do
      get "/additional-payments/claim"
      expect(response).to redirect_to("/additional-payments/first-slug")
    end
  end

  describe "GET #show" do
    context "when the `{current_slug}_before_show` filter is defined" do
      include_context :define_filter, :first_slug_before_show

      it "executes the filter" do
        get "/additional-payments/first-slug"
        expect(response.body).to include("Triggered: `first_slug_before_show` filter")
      end
    end

    context "when the `{current_slug}_before_show` filter is not defined" do
      it "renders the template for the current slug" do
        get "/additional-payments/first-slug"
        expect(response.body).to include("Rendered template for current slug: first-slug")
      end
    end
  end

  shared_examples :form_submission do
    def submit(slug)
      send(method, slug, params: {})
    end

    context "when a form object is not present for the current slug" do
      context "when the `{current_slug}_before_update` filter is not defined" do
        it "redirects to the next slug" do
          submit "/additional-payments/first-slug"
          expect(response).to redirect_to("/additional-payments/second-slug")
        end
      end

      context "when the `{current_slug}_before_update` filter is defined" do
        include_context :define_filter, :first_slug_before_update

        it "executes the filter" do
          submit "/additional-payments/first-slug"
          expect(response.body).to include("Triggered: `first_slug_before_update` filter")
        end
      end
    end

    context "when a form object is present for the current slug" do
      before do
        stub_const("Journeys::AdditionalPaymentsForTeaching::FORMS",
          {"test_dummy" => {"first-slug" => TestDummyForm, "second-slug" => TestDummyForm}})
      end

      context "when the form save succeeds" do
        before do
          allow_any_instance_of(TestDummyForm).to receive(:save).and_return(true)
        end

        context "when the `{current_slug}_after_form_save_success` filter is defined" do
          include_context :define_filter, :first_slug_after_form_save_success

          it "executes the filter" do
            submit "/additional-payments/first-slug"
            expect(response.body).to include("Triggered: `first_slug_after_form_save_success` filter")
          end
        end

        context "when the `{current_slug}_after_form_save_success` filter is not defined" do
          it "redirects to the next slug" do
            submit "/additional-payments/first-slug"
            expect(response).to redirect_to("/additional-payments/second-slug")
          end
        end

        context "when it's the end of the sequence" do
          it { expect { submit "/additional-payments/second-slug" }.to raise_error(NoMethodError, /End of sequence/) }
        end
      end

      context "when the form save fails" do
        before do
          allow_any_instance_of(TestDummyForm).to receive(:save).and_return(false)
        end

        context "when the `{current_slug}_after_form_save_failure` filter is defined" do
          include_context :define_filter, :first_slug_after_form_save_failure

          it "executes the filter" do
            submit "/additional-payments/first-slug"
            expect(response.body).to include("Triggered: `first_slug_after_form_save_failure` filter")
          end
        end

        context "when the `{current_slug}_after_form_save_failure` filter is not defined" do
          it "renders to template for the current slug" do
            submit "/additional-payments/second-slug"
            expect(response.body).to include("Rendered template for current slug: second-slug")
          end
        end
      end
    end
  end

  describe "POST #create" do
    let(:method) { :post }

    it_behaves_like :form_submission
  end

  describe "PATCH #update" do
    let(:method) { :patch }

    it_behaves_like :form_submission
  end
end
