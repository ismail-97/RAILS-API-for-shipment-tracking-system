class Shipment < ApplicationRecord
    has_many :contents
    belongs_to :customer
    belongs_to :editor
    belongs_to :flight

    validates :direction, :total, presence:true
    
    enum status: {
      received: 'received',
      shipped: 'shipped',
      delivered: 'delivered'
    }
    validates :status, inclusion: { in: :status}, allow_blank: true
    
end
