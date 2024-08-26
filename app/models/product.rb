
class Product < ApplicationRecord

    has_many :order_products


    validates :product_type, presence: true
    validates :stock, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
