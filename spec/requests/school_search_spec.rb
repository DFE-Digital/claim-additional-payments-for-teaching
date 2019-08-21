require "rails_helper"

RSpec.describe "School search", type: :request do
  describe "school_search#create request" do
    it "searches for schools using the query parameter" do
      post school_search_index_path, params: {query: "Penistone"}

      expect(response.status).to eq(200)
      expect(response.body).to include(schools(:penistone_grammar_school).name)
      expect(response.body).to include(schools(:penistone_grammar_school).address)
      expect(response.body).not_to include(schools(:hampstead_school).name)
    end

    it "includes the close date when the school is closed" do
      post school_search_index_path, params: {query: "Great Creaton Primary School"}

      expect(response.body).to include(schools(:great_creaton_primary_school).close_date.strftime("%-d %B %Y"))
    end

    it "returns an error if the query parameter is more than three characters" do
      post school_search_index_path, params: {query: "Pen"}

      expect(response.status).to eq(400)
      expect(response.body).to include({errors: ["'query' parameter must have a minimum of four characters"]}.to_json)
      expect(response.body).not_to include(schools(:penistone_grammar_school).name)
    end

    it "returns an error if no query parameter is set" do
      post school_search_index_path

      expect(response.status).to eq(400)
      expect(response.body).to include({errors: ["Expected required parameter 'query' to be set"]}.to_json)
      expect(response.body).not_to include(schools(:penistone_grammar_school).name)
    end
  end
end
