RSpec.configure do |config|
  if Bullet.enable?
    config.around(:each) do |spec|
      Bullet.start_request

      spec.run

      Bullet.end_request
    end
  end
end
