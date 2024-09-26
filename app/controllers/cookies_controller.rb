class CookiesController < BasePublicController
  include JourneyConcern

  def accept
    cookies.encrypted[:accept_cookies] = {
      value: {state: true, message: true}.to_json,
      expires: 90.days.from_now
    }

    respond_to do |format|
      format.js
      format.html { redirect_to request.env["HTTP_REFERER"] }
    end
  end

  def reject
    cookies.encrypted[:accept_cookies] = {
      value: {state: false, message: true}.to_json,
      expires: 90.days.from_now
    }

    respond_to do |format|
      format.js
      format.html { redirect_to request.env["HTTP_REFERER"] }
    end
  end

  def hide
    state = JSON.parse(cookies.encrypted[:accept_cookies])["state"]

    cookies.encrypted[:accept_cookies] = {
      value: {state:, message: false}.to_json,
      expires: 90.days.from_now
    }

    redirect_to request.env["HTTP_REFERER"]
  end

  def update
    form = CookiesForm.new(cookies_params)

    cookies.encrypted[:accept_cookies] = {
      value: {state: form.accept, message: true}.to_json,
      expires: 90.days.from_now
    }

    redirect_to cookies_path(current_journey_routing_name)
  end

  private

  def cookies_params
    params.require(:cookies).permit(:accept)
  end
end