require "capybara/rspec"
require "capybara/cuprite"

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [1200, 800],
    process_timeout: 20,
    timeout: 10
  )
end

Capybara.configure do |config|
  config.default_driver = :rack_test
  config.javascript_driver = :cuprite
  config.default_max_wait_time = 10
  config.server = :puma, {Silent: true}
end

Capybara.automatic_label_click = true

RSpec.configure do |config|
  config.around(:each, :smoke) do |example|
    Capybara.current_driver = Capybara.javascript_driver
    Capybara.run_server = false
    example.run
    Capybara.run_server = true
    Capybara.current_driver = Capybara.default_driver
  end
end
