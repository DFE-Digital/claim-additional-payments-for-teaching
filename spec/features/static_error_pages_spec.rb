require "rails_helper"

RSpec.feature "static error pages", js: true do
  scenario "404" do
    expect { visit "/404" }.not_to raise_error
  end

  scenario "422" do
    expect { visit "/422" }.not_to raise_error
  end

  scenario "500" do
    expect { visit "/500" }.not_to raise_error
  end
end
