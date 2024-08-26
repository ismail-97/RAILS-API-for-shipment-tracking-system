FactoryBot.define do
  factory :flight do
    flight_date { "2024-05-12" }
    ticket_no { "MyString" }
    ticket_price { 1 }
    airline { "MyString" }
    trip_type { "MyString" }
  end
end
