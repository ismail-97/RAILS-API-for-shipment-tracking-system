class Flight < ApplicationRecord
    has_many :shipments
    has_many :flight_expenses, dependent: :destroy
    belongs_to :traveler
    
    validates :flight_date, :ticket_no, :ticket_price, :airline, :trip_type, presence:true

end
