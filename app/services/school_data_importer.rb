require "net/http"
require "csv"

class SchoolDataImporter
  def run
    CSV.foreach(schools_data_file.path, headers: true, encoding: "ISO-8859-1:UTF-8") do |row|
      school = row_to_school(row)
      school.save!
    end
  end

  def schools_data_file
    @schools_data_file ||= begin
      response = Net::HTTP.get_response(URI(schools_csv_url))
      body = response.body.force_encoding("ISO-8859-1")
      file = Tempfile.new(["school_data_", ".csv"], encoding: "ISO-8859-1")
      file.write(body)
      file.close
      file
    end
  end

  private

  def row_to_school(row)
    local_authority = LocalAuthority.find_or_initialize_by(code: row.fetch("LA (code)"))
    local_authority.name = row.fetch("LA (name)")
    local_authority.save!

    local_authority_district = LocalAuthorityDistrict.find_or_initialize_by(code: row.fetch("DistrictAdministrative (code)"))
    local_authority_district.name = row.fetch("DistrictAdministrative (name)")
    local_authority_district.save!

    school = School.find_or_initialize_by(urn: row.fetch("URN"))
    school.name = row.fetch("EstablishmentName")
    school.street = row.fetch("Street")
    school.locality = row.fetch("Locality")
    school.town = row.fetch("Town")
    school.county = row.fetch("County (name)")
    school.postcode = row.fetch("Postcode")
    school.phase = row.fetch("PhaseOfEducation (code)").to_i
    school.school_type_group = row.fetch("EstablishmentTypeGroup (code)").to_i
    school.school_type = row.fetch("TypeOfEstablishment (code)").to_i
    school.local_authority = local_authority
    school.local_authority_district = local_authority_district
    school
  end

  def schools_csv_url
    "http://ea-edubase-api-prod.azurewebsites.net/edubase/edubasealldata#{date_string}.csv"
  end

  def date_string
    Time.zone.now.strftime("%Y%m%d")
  end
end
