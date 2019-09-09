require "rails_helper"
require "restrict_admin_by_ip_middleware"

RSpec.describe RestrictAdminByIpMiddleware do
  let(:middleware) { RestrictAdminByIpMiddleware.new(app, [blessed_ip]) }
  let(:app) { ->(env) { [200, env, ["OK"]] } }
  let(:blessed_ip) { "1.1.1.1" }

  context "requests from an allowed IP address" do
    it "passes through requests unchanged" do
      code, _env, body = middleware.call(mock_request("/test", blessed_ip))
      expect(code).to eq 200
      expect(body).to eq ["OK"]
    end
  end

  context "requests from an unrecognised IP address" do
    let(:unblessed_ip) { "2.2.2.2" }

    it "returns a 403 for anything below /admin" do
      code, _env, body = middleware.call(mock_request("/admin", unblessed_ip))
      expect(code).to eq 403
      expect(body).to eq ["Forbidden"]

      code, _env, body = middleware.call(mock_request("/admin/something", unblessed_ip))
      expect(code).to eq 403
      expect(body).to eq ["Forbidden"]
    end

    it "passes through non-admin requests" do
      code, _env, body = middleware.call(mock_request("/test", unblessed_ip))
      expect(code).to eq 200
      expect(body).to eq ["OK"]

      code, _env, body = middleware.call(mock_request("/administrators", unblessed_ip))
      expect(code).to eq 200
      expect(body).to eq ["OK"]
    end
  end

  it "handles IP addresses that arrive with a PORT number" do
    unblessed_ip_with_port = "2.2.2.2:41234"

    code, _env, body = middleware.call(mock_request("/test", unblessed_ip_with_port))
    expect(code).to eq 200
    expect(body).to eq ["OK"]

    code, _env, body = middleware.call(mock_request("/admin/something", unblessed_ip_with_port))
    expect(code).to eq 403
    expect(body).to eq ["Forbidden"]
  end

  private

  def mock_request(url, remote_ip)
    Rack::MockRequest.env_for(url, {"REMOTE_ADDR" => remote_ip})
  end
end
