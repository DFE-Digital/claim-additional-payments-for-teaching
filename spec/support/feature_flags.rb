RSpec.configure do |config|
  config.before :each do
    data = RSpec.current_example.metadata[:feature_flag]

    if data.present?
      Array(data).each do |name|
        FeatureFlag.create!(name:, enabled: true)
      end
    end
  end
end
