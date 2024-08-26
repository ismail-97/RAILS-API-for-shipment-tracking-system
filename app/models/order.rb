class Order < ApplicationRecord
  belongs_to :customer
  has_many :order_products

  validates :order_date, :total, presence: true

end
