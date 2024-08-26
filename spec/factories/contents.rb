FactoryBot.define do
  factory :content do
    content_type { "shoes" }
    weight { 1 }
    items_number { 1 }
    kg_price { 1 }
    shipment { nil }
  end
end
