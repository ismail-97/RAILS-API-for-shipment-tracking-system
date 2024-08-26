FactoryBot.define do
  factory :editor do
    name { "MyString" }
    email { "MyString" }
    password_digest { "MyString" }
    super_editor { false }
  end
end
