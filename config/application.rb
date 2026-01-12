require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Dailynews
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    app_env = ENV["APP_ENV"] || Rails.env
    credentials_dir = Rails.root.join("config", "credentials")
    credentials_file = credentials_dir.join("#{app_env}.yml.enc")
    key_file = credentials_dir.join("#{app_env}.key")

    if credentials_file.exist? && key_file.exist?
      config.credentials.content_path = credentials_file
      config.credentials.key_path = key_file
      puts "✓ Using environment-specific credentials: #{app_env}"
    else
      puts "✓ Using default credentials (#{app_env} specific not found)"
    end
  end
end
