# Ensures all form classes are available in the journey
unless Rails.application.config.eager_load
  Rails.application.reloader.to_prepare do
    Dir["#{Rails.root}/app/forms/**/*.rb"].each { |file| require_dependency(file) }
  end
end
