require "test_helper"

class Madmin::FieldTest < ActiveSupport::TestCase
  test "required?" do
    assert PostResource.attributes[:title].field.required?
    refute PostResource.attributes[:id].field.required?
  end

  test "hint" do
    assert_equal "Enter your given name", UserResource.attributes[:first_name].field.hint
    assert_nil UserResource.attributes[:created_at].field.hint
  end

  test "searchable?" do
    assert UserResource.attributes[:first_name].field.searchable?
    refute UserResource.attributes[:created_at].field.searchable?
  end

  test "visible?" do
    assert UserResource.attributes[:name].field.visible?(:index)
  end
end
