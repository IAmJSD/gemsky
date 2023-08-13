class User < ApplicationRecord
    include EmailConcern
    validates :email, uniqueness: true

    has_secure_password

    has_many :user_tokens, dependent: :destroy
end
