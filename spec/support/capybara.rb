require 'capybara/rspec'
require 'selenium/webdriver'
require "capybara/cuprite"

# Register Cuprite driver with mobile configuration
Capybara.register_driver :cuprite do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [ 390, 844 ],                    # Mobile screen size (iPhone 13 Pro)
    browser_options: {
      'headless': nil,                          # Run in headless mode
      'no-sandbox': nil,                        # Required for some environments
      'disable-dev-shm-usage': nil,             # Prevents shared memory issues
      'disable-gpu': nil,                       # Prevents GPU issues in headless mode
      'disable-web-security': nil               # Helpful for testing
    },
    process_timeout: 10,                        # Timeout for browser process
    timeout: 10,                                # Timeout for commands
    js_errors: true                             # Raise errors on JavaScript errors
  )
end

# Use Cuprite as the JavaScript driver
Capybara.javascript_driver = :cuprite
Capybara.default_driver = :cuprite

# Configure Capybara timeouts
Capybara.configure do |config|
  config.default_max_wait_time = 10
  config.server_port = 9887 + ENV['TEST_ENV_NUMBER'].to_i
end

# RSpec configuration for Capybara
RSpec.configure do |config|
  # Capybara configuration for system tests
  config.before(:each, type: :system) do
    driven_by :cuprite
  end
end
