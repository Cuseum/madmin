require "test_helper"

class NestedHasManyTest < ActiveSupport::TestCase
  test "checks for the right field class" do
    field = UserResource.attributes[:posts].field
    field_comment = UserResource.attributes[:comments].field

    # Make sure :posts is a :nested_has_many type
    assert field.instance_of?(Madmin::Fields::NestedHasMany)
    refute field_comment.instance_of?(Madmin::Fields::NestedHasMany)
    assert_equal field.resource, PostResource
  end

  test "skips fields which is skipped in configuration" do
    field = UserResource.attributes[:posts].field

    # Make sure :enum is skipped in the UserResource
    refute field.to_param.values.flatten.include?(:enum)
    assert field.to_param.values.flatten.include?(:body)
  end

  test "whitelists unskipped and required params" do
    field = UserResource.attributes[:posts].field
    expected_params = [:title, :metadata, :body, :image, "user_id", "_destroy", "id"]
    assert expected_params.all? { |p| field.to_param[:posts_attributes].include?(p) }
  end
end

class NestedHasOneTest < ActiveSupport::TestCase
  test "checks for the right field class" do
    field = PostResource.attributes[:post_stat].field

    assert field.instance_of?(Madmin::Fields::NestedHasOne)
    assert_equal PostStatResource, field.resource
  end

  test "skips fields which are skipped in configuration" do
    field = PostResource.attributes[:post_stat].field

    # :shared is in skip: %I[shared]
    refute field.to_param.values.flatten.include?(:shared)
    assert field.to_param.values.flatten.include?(:drafts_saved)
  end

  test "whitelists unskipped and required params" do
    field = PostResource.attributes[:post_stat].field
    expected_params = [:drafts_saved, :keywords, "_destroy", "id"]
    assert expected_params.all? { |p| field.to_param[:post_stat_attributes].include?(p) }
  end

  test "destroy? defaults to true" do
    field = PostResource.attributes[:post_stat].field
    assert field.destroy?
  end

  test "destroy? returns false when allow_destroy: false is set" do
    field = Madmin::Fields::NestedHasOne.new(
      attribute_name: :post_stat,
      model: Post,
      resource: PostResource,
      options: ActiveSupport::OrderedOptions.new.merge(allow_destroy: false)
    )
    refute field.destroy?
  end

  test "nested_attributes respects form_attributes order when form block is defined" do
    field = PostResource.attributes[:post_stat].field

    # Without form_attributes, order follows resource.attributes
    attrs_without_form = field.nested_attributes.keys
    assert_equal :drafts_saved, attrs_without_form.find { |n| [:drafts_saved, :keywords].include?(n) }

    # With form_attributes defining keywords before drafts_saved
    PostStatResource.form_attributes = [:keywords, :drafts_saved]

    attrs_with_form = field.nested_attributes.keys
    assert_equal [:keywords, :drafts_saved], attrs_with_form.select { |n| [:keywords, :drafts_saved].include?(n) }
  ensure
    PostStatResource.form_attributes = nil
  end

  test "form_block is nil when nested resource form does not use row/col" do
    # PostStatResource uses a plain section (no row/col) so form_block stays nil
    assert_nil PostStatResource.form_block
  end
end
