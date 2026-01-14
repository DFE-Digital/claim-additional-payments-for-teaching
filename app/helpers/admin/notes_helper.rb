module Admin
  module NotesHelper
    def body_with_anchors(body)
      urls = URI.extract(body, %w[http https]).uniq
      html_body = body.dup
      urls.each { |url| html_body.gsub!(url, govuk_link_to(url, url, new_tab: "")) }
      html_body.html_safe
    end
  end
end
