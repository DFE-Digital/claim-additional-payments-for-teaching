json.data do
  json.array! @schools do |school|
    json.id school.id
    json.name school.name
  end
end

json.errors current_claim.errors
