module Verify
  # A Rack application that can be used in the test suite to simulate the GOV.UK
  # Verify SSO process.
  #
  # The Rack app responds with a form that when submitted will POST back to
  # `callback_path` with a `SAMLResponse` parameter set to
  # `FakeSso::IDENTITY_VERIFIED_SAML_RESPONSE`.
  class FakeSso
    IDENTITY_VERIFIED_SAML_RESPONSE = "IDENTITY_VERIFIED_SAML"

    def initialize(callback_path)
      @callback_path = callback_path
    end

    def call(env)
      [200, {"Content-Type" => "text/html"}, [identity_verified_form]]
    end

    private

    def identity_verified_form
      <<~HEREDOC
        <html><body>
          <form action="#{@callback_path}" method="POST">
            <input type="hidden" name="SAMLResponse" value="#{IDENTITY_VERIFIED_SAML_RESPONSE}">
            <input type="submit" value="Perform identity check">
          </form>
        </body></html>
      HEREDOC
    end
  end
end
