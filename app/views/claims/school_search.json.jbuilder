json.data do
  json.array! @schools do |school|
    json.id school.id
    json.name school.name
    json.address school.address
  end
end

json.errors current_claim.errors
