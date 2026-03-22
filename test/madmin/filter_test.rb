require "test_helper"

class SimpleFilter < Madmin::Filters::BaseFilter
  def apply(query, value)
    query.where(first_name: value)
  end
end

class CustomNameFilter < Madmin::Filters::BaseFilter
  def name
    "My Custom Filter"
  end

  def apply(query, value)
    query.where(last_name: value)
  end
end

class DefaultValueFilter < Madmin::Filters::BaseFilter
  self.default = "active"

  def apply(query, value)
    query.where(admin: value)
  end
end

class NotImplementedFilter < Madmin::Filters::BaseFilter
end

class FilteredResource < Madmin::Resource
  model User
  filter SimpleFilter
  filter DefaultValueFilter
end

class FilterTest < ActiveSupport::TestCase
  test "filter id is derived from class name" do
    filter = SimpleFilter.new
    assert_equal "simple_filter", filter.id
  end

  test "filter name defaults to humanized class name without Filter suffix" do
    filter = SimpleFilter.new
    assert_equal "Simple", filter.name
  end

  test "filter name can be overridden" do
    filter = CustomNameFilter.new
    assert_equal "My Custom Filter", filter.name
  end

  test "filter default is nil by default" do
    filter = SimpleFilter.new
    assert_nil SimpleFilter.default
  end

  test "filter default can be set at the class level" do
    assert_equal "active", DefaultValueFilter.default
  end

  test "applied_or_default_value returns the applied value when present" do
    filter = SimpleFilter.new
    assert_equal "Alice", filter.applied_or_default_value("simple_filter" => "Alice")
  end

  test "applied_or_default_value returns default when value is absent" do
    filter = DefaultValueFilter.new
    assert_equal "active", filter.applied_or_default_value({})
  end

  test "applied_or_default_value returns nil default when not set and value is absent" do
    filter = SimpleFilter.new
    assert_nil filter.applied_or_default_value({})
  end

  test "apply raises NotImplementedError when not overridden" do
    filter = NotImplementedFilter.new
    assert_raises(NotImplementedError) { filter.apply(User.all, "anything") }
  end

  test "apply_query delegates to apply" do
    filter = SimpleFilter.new
    result = filter.apply_query(User.all, "Alice")
    assert_kind_of ActiveRecord::Relation, result
  end

  test "default is not shared between filter subclasses" do
    assert_nil SimpleFilter.default
    assert_equal "active", DefaultValueFilter.default
  end

  test "resource registers filters via filter class method" do
    assert_includes FilteredResource.filters, SimpleFilter
    assert_includes FilteredResource.filters, DefaultValueFilter
  end

  test "filters are not inherited by subclasses" do
    subclass = Class.new(FilteredResource)
    assert_equal [], subclass.filters
  end

  test "resource can register multiple filters" do
    assert_equal 2, FilteredResource.filters.length
  end
end
