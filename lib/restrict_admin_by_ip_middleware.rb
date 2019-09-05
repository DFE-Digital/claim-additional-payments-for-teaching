class RestrictAdminByIpMiddleware
  def initialize(app, allowed_ips)
    @app = app
    @allowed_ips = allowed_ips.map { |ip| IPAddr.new(ip) }
  end

  def call(env)
    if restricted?(env)
      [403, {"Content-Type" => "text/plain"}, ["Forbidden"]]
    else
      @app.call(env)
    end
  end

  private

  def restricted?(env)
    req = Rack::Request.new(env)

    restricted_route?(req) && !allowed_ip?(req)
  end

  def restricted_route?(req)
    req.path == "/admin" || req.path.start_with?("/admin/")
  end

  def allowed_ip?(req)
    @allowed_ips.any? { |ip| ip.include?(req.ip) }
  end
end
