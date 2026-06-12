require "rails_helper"

RSpec.feature "Robots", feature_flag: [:eytfi_journey] do
  before do
    create(
      :journey_configuration,
      :early_years_teachers_financial_incentive_payments
    )

    create(:journey_configuration, :further_education_payments)
  end

  describe "metatag" do
    context "when on an indexable page" do
      it "excludes noindex from the robots meta tag" do
        visit "/early-years-teachers-recognition-payments/landing-page"

        expect(page).to(
          have_selector(
            "meta[name='robots'][content='index,nofollow']",
            visible: false
          )
        )

        visit "/early-years-teachers-recognition-payments/guidance"

        expect(page).to(
          have_selector(
            "meta[name='robots'][content='index,nofollow']",
            visible: false
          )
        )
      end
    end

    context "when not on an indexable page" do
      it "includes noindex in the robots meta tag" do
        visit "/further-education-payments/landing-page"

        expect(page).to(
          have_selector(
            "meta[name='robots'][content='noindex,nofollow']",
            visible: false
          )
        )
      end
    end
  end
end
