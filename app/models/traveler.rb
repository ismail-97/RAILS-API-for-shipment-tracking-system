class Traveler < ApplicationRecord
    belongs_to :editor
    has_many :flights

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
