class Content < ApplicationRecord
  belongs_to :shipment

  enum :content_type, {
    shoes: "shoes", 
    clothes: "clothes", 
    cosmetics: "cosmetics", 
    food_products: "food_products", 
    home_related: "home_related"}, validate: true

  validates :weight, :items_number, :kg_price, presence:true
  validates :weight, :items_number, :kg_price, numericality: { greater_than: 0 }

end
