class Editor < ApplicationRecord
    has_many :customers
    has_many :shipments
    has_many :travelers

    has_secure_password


    validates :name, :email, presence: true

    validates :password, length: { minimum: 6 }, on: :create
    validates :password, length: { minimum: 6 }, on: :update, allow_blank: true

    validates :email, uniqueness: true
    validate :valid_email_format

    #presence validation on booleans is not working, so I used inclusion instead
    validates :super_editor, inclusion: { in: [ true, false ] }

    def valid_email_format
        unless email =~ /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
          errors.add(:email, "must be a valid email")
        end
      end

end
