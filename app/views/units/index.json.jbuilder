json.array!(@units) do |unit|
  json.extract! unit, :no, :price, :area, :flat_type, :block_id
  json.url unit_url(unit, format: :json)
end
