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

  test "hint is nil when hint: nil is passed" do
    assert_nil UserResource.attributes[:email].field.hint
  end

  test "hint uses inline value when hint: string is passed" do
    hint = UserResource.attributes[:bio].field.hint
    assert_equal "Custom inline hint", hint
    assert_predicate hint, :html_safe?
  end

  test "searchable?" do
    assert UserResource.attributes[:first_name].field.searchable?
    refute UserResource.attributes[:created_at].field.searchable?
  end

  test "visible?" do
    assert UserResource.attributes[:name].field.visible?(:index)
  end

  test "input_html_options is empty when no relevant options set" do
    field = UserResource.attributes[:first_name].field
    assert_equal({}, field.input_html_options)
  end

  test "input_html_options includes readonly when set" do
    field = Madmin::Fields::String.new(
      attribute_name: :first_name,
      model: User,
      resource: UserResource,
      options: ActiveSupport::OrderedOptions.new.merge(readonly: true)
    )
    assert_equal({readonly: true}, field.input_html_options)
  end

  test "input_html_options includes disabled when set" do
    field = Madmin::Fields::String.new(
      attribute_name: :first_name,
      model: User,
      resource: UserResource,
      options: ActiveSupport::OrderedOptions.new.merge(disabled: true)
    )
    assert_equal({disabled: true}, field.input_html_options)
  end

  test "input_html_options includes placeholder when set" do
    field = Madmin::Fields::String.new(
      attribute_name: :first_name,
      model: User,
      resource: UserResource,
      options: ActiveSupport::OrderedOptions.new.merge(placeholder: "Enter name")
    )
    assert_equal({placeholder: "Enter name"}, field.input_html_options)
  end

  test "input_html_options excludes unknown options" do
    field = Madmin::Fields::String.new(
      attribute_name: :first_name,
      model: User,
      resource: UserResource,
      options: ActiveSupport::OrderedOptions.new.merge(readonly: true, hint: "some hint")
    )
    assert_equal({readonly: true}, field.input_html_options)
  end
end
