if @schools.present?
  json.data do
    json.array! @schools do |school|
      json.id school.id
      json.name school.name
      json.address school.address
      json.closeDate l(school.close_date) if school.close_date.present?
    end
  end
end

json.errors errors if errors.present?
