require "rails_helper"

RSpec.describe "School search", type: :request do
  describe "school_search#create request" do
    it "searches for schools by name using the query parameter" do
      post school_search_index_path, params: {query: "Penistone"}

      expect(response.status).to eq(200)
      expect(response.body).to include(schools(:penistone_grammar_school).name)
      expect(response.body).to include(schools(:penistone_grammar_school).address)
      expect(response.body).not_to include(schools(:hampstead_school).name)
    end

    it "searches for schools by postcode using the query parameter" do
      post school_search_index_path, params: {query: "s367"}

      expect(response.status).to eq(200)
      expect(response.body).to include(schools(:penistone_grammar_school).name)
      expect(response.body).not_to include(schools(:hampstead_school).name)
    end

    it "returns an error if the query parameter is less than three characters" do
      post school_search_index_path, params: {query: "Pe"}

      expect(response.status).to eq(400)
      expect(response.body).to include({errors: [School::SEARCH_NOT_ENOUGH_CHARACTERS_ERROR]}.to_json)
      expect(response.body).not_to include(schools(:penistone_grammar_school).name)
    end

    it "returns an error if no query parameter is set" do
      post school_search_index_path

      expect(response.status).to eq(400)
      expect(response.body).to include({errors: ["Expected required parameter 'query' to be set"]}.to_json)
      expect(response.body).not_to include(schools(:penistone_grammar_school).name)
    end

    it "includes closed schools by default" do
      post school_search_index_path, params: {query: "The Samuel Lister Academy"}

      expect(response.body).to include(schools(:the_samuel_lister_academy).name)
    end

    it "includes the close date when the school is closed" do
      post school_search_index_path, params: {query: "The Samuel Lister Academy"}

      expect(response.body).to include(schools(:the_samuel_lister_academy).close_date.strftime("%-d %B %Y"))
    end

    it "includes closed schools when requested" do
      post school_search_index_path, params: {query: "The Samuel Lister Academy", exclude_closed: false}

      expect(response.body).to include(schools(:the_samuel_lister_academy).name)
    end

    it "excludes closed schools when requested" do
      post school_search_index_path, params: {query: "The Samuel Lister Academy", exclude_closed: true}

      expect(response.body).not_to include(schools(:the_samuel_lister_academy).name)
    end
  end
end
