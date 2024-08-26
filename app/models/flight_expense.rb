class FlightExpense < ApplicationRecord
    belongs_to :flight
    validates :expense_type, :amount, :direction, presence:true
    validates :amount, numericality: { only_integer: true }

end
