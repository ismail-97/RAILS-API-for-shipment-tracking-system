class Customer < ApplicationRecord
    has_many :shipments
    has_many :orders
    belongs_to :editor

    validates :name, :phone, presence: true
    validates :phone, uniqueness: true
    validate :valid_phone_format

    private
  
    def valid_phone_format
      unless phone =~ /\A\d{10}\z/
        errors.add(:phone, "must be a valid 10-digit phone number")
      end
    end
end
