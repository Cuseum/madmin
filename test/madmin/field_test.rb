require "test_helper"

class Madmin::FieldTest < ActiveSupport::TestCase
  test "label_hidden?" do
    assert UserResource.attributes[:ssn].field.label_hidden?
    refute UserResource.attributes[:first_name].field.label_hidden?
  end

  test "required?" do
    assert PostResource.attributes[:title].field.required?
    refute PostResource.attributes[:id].field.required?
  end

  test "hint" do
    assert_equal "Enter your given name", UserResource.attributes[:first_name].field.hint
    assert_nil UserResource.attributes[:created_at].field.hint
  end

  test "hint with html" do
    hint = UserResource.attributes[:last_name].field.hint
    assert_equal "Your <strong>family</strong> name", hint
    assert_predicate hint, :html_safe?
  end

  test "hint for nested has_one attribute" do
    nested_field = PostResource.attributes[:post_stat].field.nested_attributes[:drafts_saved].field
    assert_equal "Number of times the draft was saved", nested_field.hint
  end

  test "searchable?" do
    assert UserResource.attributes[:first_name].field.searchable?
    refute UserResource.attributes[:created_at].field.searchable?
  end

  test "visible?" do
    assert UserResource.attributes[:name].field.visible?(:index)
  end
end
