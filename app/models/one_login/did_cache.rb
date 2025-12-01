require "json"
require "net/http"

class OneLogin::DidCache
  # public api to use document
  # if document not present it will fetch
  # if it determines document has expired it will first refresh the document
  def self.document
    @cache ||= new

    @cache.document
  end

  def self.clear_cache!
    @cache ||= new
    @cache.clear_cache!
  end

  def self.cache
    @cache
  end

  attr_reader :document_object, :expires_at

  def initialize(document_object: nil, expires_at: nil)
    @document_object = document_object
    @expires_at = expires_at
  end

  def expired?
    return true if expires_at.nil?

    Time.now > expires_at
  end

  def clear_cache!
    @document_object = nil
  end

  def document
    if document_object.nil?
      refresh_document
    end

    if expired?
      refresh_document
    end

    document_object
  end

  private

  def did_uri
    URI(ENV["ONELOGIN_DID_URL"])
  end

  def refresh_document
    response = Net::HTTP.get_response(did_uri)

    if response.is_a?(Net::HTTPSuccess)
      new_doc = OneLogin::Did.new(document_hash: JSON.parse(response.body))
      set_expiry_from_response(response)
      @document_object = new_doc
    else
      increment_expiry
    end
  end

  def increment_expiry
    current_expiry = expires_at || Time.now
    new_expiry = current_expiry + 1.hour

    @expires_at = new_expiry
  end

  def set_expiry_from_response(response)
    new_expiry = Time.now + cache_control_max_age(response).seconds

    @expires_at = new_expiry
  end

  # seconds
  def cache_control_max_age(response)
    if response["Cache-Control"]
      matches = response["Cache-Control"].match(/max-age=(?<max_age>\d+)/)
      matches[:max_age].to_i
    else
      default_cache_control_max_age
    end
  end

  # seconds
  def default_cache_control_max_age
    3600
  end
end
