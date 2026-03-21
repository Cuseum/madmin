require "test_helper"

class PostDialogCommentsResource < Madmin::Resource
  model Post

  attribute :id, form: false
  attribute :title
  attribute :comments, :dialog_has_many
end

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

class Madmin::DialogHasManyFieldTest < ActiveSupport::TestCase
  def field
    PostDialogCommentsResource.attributes[:comments].field
  end

  test "field type is dialog_has_many" do
    assert_instance_of Madmin::Fields::DialogHasMany, field
  end

  test "frame_id is derived from attribute name" do
    assert_equal "madmin-dialog-frame-comments", field.frame_id
  end

  test "dialog_id is derived from attribute name" do
    assert_equal "madmin-dialog-comments", field.dialog_id
  end

  test "associated_resource returns the CommentResource" do
    assert_equal CommentResource, field.associated_resource
  end

  test "index_attributes returns attributes visible in CommentResource index" do
    attrs = field.index_attributes
    assert_kind_of Array, attrs
    assert attrs.all? { |a| a.is_a?(Madmin::Resource::Attribute) }
    attr_names = attrs.map(&:name)
    # id and created_at are in the default index attributes list
    assert_includes attr_names, :id
    assert_includes attr_names, :created_at
  end

  test "paginateable? is false" do
    refute field.paginateable?
  end

  test "to_param returns the attribute name" do
    assert_equal :comments, field.to_param
  end

  test "edit_dialog_path includes dialog params" do
    comment = Comment.first || skip("No comments in fixture")
    path = field.edit_dialog_path(comment)
    assert_includes path, "dialog=1"
    assert_includes path, "frame_id=madmin-dialog-frame-comments"
  end
end
