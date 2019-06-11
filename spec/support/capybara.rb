require "capybara/rspec"

chrome_bin = ENV.fetch("GOOGLE_CHROME_BIN", nil)

Capybara.register_driver :headless_chrome do |app|
  Selenium::WebDriver::Chrome.path = chrome_bin if chrome_bin.present?
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: Selenium::WebDriver::Chrome::Options.new(
      args: %w[headless disable-dev-shm-usage no-sandbox]
    )
  )
end

Capybara.configure do |config|
  config.default_driver = :rack_test
  config.javascript_driver = :headless_chrome
end
