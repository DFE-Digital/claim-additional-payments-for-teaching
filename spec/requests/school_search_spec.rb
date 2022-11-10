require "rails_helper"

RSpec.describe "School search", type: :request do
  describe "school_search#create request" do
    let!(:school_1) { create(:school) }
    let!(:school_2) { create(:school, :closed) }

    it "searches for schools by name using the query parameter" do
      post school_search_index_path, params: {query: school_1.name}

      expect(response.status).to eq(200)
      expect(response.body).to include(school_1.name)
      expect(response.body).to include(school_1.address)
      expect(response.body).not_to include(school_2.name)
    end

    it "searches for schools by postcode using the query parameter" do
      post school_search_index_path, params: {query: school_1.postcode}

      expect(response.status).to eq(200)
      expect(response.body).to include(school_1.name)
      expect(response.body).not_to include(school_2.name)
    end

    it "returns an error if the query parameter is less than three characters" do
      post school_search_index_path, params: {query: "ab"}

      expect(response.status).to eq(400)
      expect(response.body).to include({errors: [School::SEARCH_NOT_ENOUGH_CHARACTERS_ERROR]}.to_json)
      expect(response.body).not_to include(school_1.name)
      expect(response.body).not_to include(school_2.name)
    end

    it "returns an error if no query parameter is set" do
      post school_search_index_path

      expect(response.status).to eq(400)
      expect(response.body).to include({errors: ["Expected required parameter 'query' to be set"]}.to_json)
      expect(response.body).not_to include(school_1.name)
      expect(response.body).not_to include(school_2.name)
    end

    it "includes closed schools by default" do
      post school_search_index_path, params: {query: school_2.name}

      expect(response.body).to include(school_2.name)
    end

    it "includes the close date when the school is closed" do
      post school_search_index_path, params: {query: school_2.name}

      expect(response.body).to include(school_2.close_date.strftime("%-d %B %Y"))
    end

    it "includes closed schools when requested" do
      post school_search_index_path, params: {query: school_2.name, exclude_closed: false}

      expect(response.body).to include(school_2.name)
    end

    it "excludes closed schools when requested" do
      post school_search_index_path, params: {query: school_2.name, exclude_closed: true}

      expect(response.body).not_to include(school_2.name)
    end

    context "with a school which is not yet open" do
      let!(:unopened_school) { create(:school, open_date: 10.days.from_now, name: "Penistone Grammar School") }
      let!(:other_school_similar_name) { create(:school, name: "Penistone duplicate") }

      it "excludes schools that have GIAS OpenDate that is in future" do
        post school_search_index_path, params: {query: "Penistone", exclude_closed: true}

        expect(response.body).not_to include(unopened_school.name)
        expect(response.body).to include(other_school_similar_name.name)
      end
    end
  end
end
