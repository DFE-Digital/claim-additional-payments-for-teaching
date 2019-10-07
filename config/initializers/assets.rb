# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join("node_modules")

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )
Rails.application.config.assets.precompile += %w[js_check.js google_analytics.js google_analytics/analytics.js accessible-autocomplete/src/autocomplete.css]

# Include the url_helpers in the asset pipeline
# We use url helpers in the some of .js.erb, calling them statically doesn't
# set the correct defaults we need to include the helpers instead.
Rails.application.config.assets.configure do |env|
  env.context_class.class_eval do
    include Rails.application.routes.url_helpers
  end
end
