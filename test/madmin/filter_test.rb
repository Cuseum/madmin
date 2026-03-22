require "test_helper"

# Filter that uses the new nested comparator format
class NameFilter < Madmin::Filters::BaseFilter
  def apply(query, value)
    is_values = values_for(value, :is)
    is_not_values = values_for(value, :is_not)
    query = query.where(first_name: is_values) if is_values.any?
    query = query.where.not(first_name: is_not_values) if is_not_values.any?
    query
  end
end

# Legacy-style filter (flat value) kept to verify the API is format-agnostic
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
  filter NameFilter
  filter DefaultValueFilter
end

class FilterTest < ActiveSupport::TestCase
  # --- id / name ---

  test "filter id is derived from class name without Filter suffix" do
    filter = NameFilter.new
    assert_equal "name", filter.id
  end

  test "filter name defaults to humanized class name without Filter suffix" do
    filter = NameFilter.new
    assert_equal "Name", filter.name
  end

  test "filter name can be overridden" do
    filter = CustomNameFilter.new
    assert_equal "My Custom Filter", filter.name
  end

  # --- default ---

  test "filter default is nil by default" do
    assert_nil SimpleFilter.default
  end

  test "filter default can be set at the class level" do
    assert_equal "active", DefaultValueFilter.default
  end

  test "default is not shared between filter subclasses" do
    assert_nil SimpleFilter.default
    assert_equal "active", DefaultValueFilter.default
  end

  # --- applied_or_default_value ---

  test "applied_or_default_value returns nested hash when present in applied_filters" do
    filter = NameFilter.new
    value = {"name" => {"is" => ["Alice"]}}
    assert_equal({"is" => ["Alice"]}, filter.applied_or_default_value(value))
  end

  test "applied_or_default_value returns default when filter is absent from applied_filters" do
    filter = DefaultValueFilter.new
    assert_equal "active", filter.applied_or_default_value({})
  end

  test "applied_or_default_value returns nil default when not set and filter is absent" do
    filter = SimpleFilter.new
    assert_nil filter.applied_or_default_value({})
  end

  # --- values_for ---

  test "values_for returns array of values for matching comparator (string key)" do
    filter = NameFilter.new
    value = {"is" => ["Alice", "Bob"], "is_not" => ["Charlie"]}
    assert_equal ["Alice", "Bob"], filter.values_for(value, :is)
    assert_equal ["Charlie"], filter.values_for(value, :is_not)
  end

  test "values_for accepts symbol comparator keys in value hash" do
    filter = NameFilter.new
    value = {is: ["Alice"]}
    assert_equal ["Alice"], filter.values_for(value, :is)
  end

  test "values_for returns empty array for missing comparator" do
    filter = NameFilter.new
    assert_equal [], filter.values_for({"is" => ["Alice"]}, :gt)
  end

  test "values_for returns empty array when value is not a hash" do
    filter = NameFilter.new
    assert_equal [], filter.values_for("plain_string", :is)
    assert_equal [], filter.values_for(nil, :is)
  end

  test "values_for wraps a single (non-array) value in an array" do
    filter = NameFilter.new
    assert_equal ["active"], filter.values_for({"is" => "active"}, :is)
  end

  # --- apply / apply_query ---

  test "apply raises NotImplementedError when not overridden" do
    filter = NotImplementedFilter.new
    assert_raises(NotImplementedError) { filter.apply(User.all, {}) }
  end

  test "apply_query delegates to apply" do
    filter = NameFilter.new
    result = filter.apply_query(User.all, {"is" => ["Alice"]})
    assert_kind_of ActiveRecord::Relation, result
  end

  test "apply filters by is comparator" do
    filter = NameFilter.new
    result = filter.apply(User.all, {"is" => ["Alice"]})
    assert_kind_of ActiveRecord::Relation, result
  end

  test "apply filters by is_not comparator" do
    filter = NameFilter.new
    result = filter.apply(User.all, {"is_not" => ["Alice"]})
    assert_kind_of ActiveRecord::Relation, result
  end

  test "apply with empty value hash returns unmodified query" do
    filter = NameFilter.new
    original = User.all
    result = filter.apply(original, {})
    assert_equal original.to_sql, result.to_sql
  end

  # --- resource DSL ---

  test "resource registers filters via filter class method" do
    assert_includes FilteredResource.filters, NameFilter
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
