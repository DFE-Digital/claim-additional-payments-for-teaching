require "open-uri"
require "csv"

class SchoolDataImporter
  def run
    temp_csv_file = URI.parse(schools_csv_url).open("r:ISO-8859-1")

    CSV.parse(temp_csv_file, headers: true).each do |row|
      school = row_to_school(row)
      school.save!
    end
  end

  private

  def row_to_school(row)
    local_authority = LocalAuthority.find_or_initialize_by(code: row.fetch("LA (code)"))
    local_authority.name = row.fetch("LA (name)")
    local_authority.save!
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
    school
  end

  def schools_csv_url
    "http://ea-edubase-api-prod.azurewebsites.net/edubase/edubasealldata#{date_string}.csv"
  end

  def date_string
    Time.zone.now.strftime("%Y%m%d")
  end
end
