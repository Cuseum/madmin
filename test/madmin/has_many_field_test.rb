require "test_helper"

class HasManyFieldTest < ActiveSupport::TestCase
  setup do
    @field = UserResource.attributes[:comments].field
    @user = users(:one)
  end

  test "paginateable? returns true" do
    assert @field.paginateable?
  end

  if Gem::Version.new(Pagy::VERSION) >= Gem::Version.new("43.0.0.rc")
    test "paginated_value returns pagy object and records using Pagy::Method" do
      pagy, records = @field.paginated_value(@user, {})
      # Pagy::Method returns Pagy::Offset (a Pagy subclass), so use assert_kind_of
      assert_kind_of Pagy, pagy
      assert_respond_to records, :each
    end

    test "paginated_value does not raise for Pagy::Method path" do
      assert_nothing_raised { @field.paginated_value(@user, {}) }
    end
  else
    test "params returns an empty hash for Pagy::Backend compatibility" do
      # Pagy::Backend internally calls `params` on the including object.
      # Without this method defined, paginated_value raises NoMethodError.
      assert_equal({}, @field.params)
    end

    test "paginated_value returns pagy object and records using Pagy::Backend" do
      pagy, records = @field.paginated_value(@user, {})
      assert_kind_of Pagy, pagy
      assert_respond_to records, :each
    end

    test "paginated_value does not raise NoMethodError for params when using Pagy::Backend" do
      # Before the fix, this raised: NoMethodError: undefined method 'params'
      # because Pagy::Backend calls `params` on the including object internally.
      assert_nothing_raised { @field.paginated_value(@user, {}) }
    end
  end
end
