class PostcodeSearch
  attr_reader :postcode

  def initialize(postcode)
    raise ArgumentError if postcode.nil?

    @postcode = postcode
    @error = false
  end

  def addresses
    @addresses ||= Rails.cache.fetch("address_data/#{postcode}", expires_in: 1.hour) do
      OrdnanceSurvey::Client.new.api.search_places.index(
        params: {postcode: postcode}
      )
    end
  rescue OrdnanceSurvey::Client::ResponseError => e
    @error = true
    Sentry.capture_exception(e)
  end

  def api_error?
    return true if @error

    addresses

    @error
  end
end
