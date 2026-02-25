require "test_helper"

class FooBarBahResource < Madmin::Resource; end

class BlockStyleResource < Madmin::Resource
  model User

  index do
    attribute :first_name
    attribute :last_name
  end

  show do
    attribute :first_name
    attribute :last_name
    attribute :email
  end

  form do
    attribute :first_name
    attribute :last_name
  end
end

class FormTabResource < Madmin::Resource
  model User

  form_tab :personal do
    attribute :first_name
    attribute :last_name
  end

  form_tab :contact, label: "Contact Info" do
    attribute :email
  end
end

class FormSectionResource < Madmin::Resource
  model User

  section :general do
    attribute :first_name
    attribute :last_name
  end

  section :contact, label: "Contact Info" do
    attribute :email
  end
end

class ResourceTest < ActiveSupport::TestCase
  test "searchable_attributes" do
    searchable_attribute_names = UserResource.searchable_attributes.map(&:name)
    assert_includes searchable_attribute_names, :first_name
  end

  test "rich_text" do
    assert_equal :rich_text, PostResource.attributes[:body].type
  end

  test "friendly_name" do
    assert_equal "User", UserResource.friendly_name
    assert_equal "Foo Bar Bah", FooBarBahResource.friendly_name
  end

  test "block-style index attributes" do
    assert BlockStyleResource.attributes[:first_name].field.visible?(:index)
    assert BlockStyleResource.attributes[:last_name].field.visible?(:index)
    refute BlockStyleResource.attributes[:email].field.visible?(:index)
  end

  test "block-style show attributes" do
    assert BlockStyleResource.attributes[:first_name].field.visible?(:show)
    assert BlockStyleResource.attributes[:last_name].field.visible?(:show)
    assert BlockStyleResource.attributes[:email].field.visible?(:show)
  end

  test "block-style form attributes" do
    assert BlockStyleResource.attributes[:first_name].field.visible?(:form)
    assert BlockStyleResource.attributes[:last_name].field.visible?(:form)
    refute BlockStyleResource.attributes[:email].field.visible?(:form)
  end

  test "block-style form attributes visible for new and edit actions" do
    assert BlockStyleResource.attributes[:first_name].field.visible?(:new)
    assert BlockStyleResource.attributes[:first_name].field.visible?(:edit)
    refute BlockStyleResource.attributes[:email].field.visible?(:new)
    refute BlockStyleResource.attributes[:email].field.visible?(:edit)
  end

  test "block-style permitted_params" do
    permitted = BlockStyleResource.permitted_params
    assert_includes permitted, :first_name
    assert_includes permitted, :last_name
    refute_includes permitted, :email
  end

  test "form_tab registers tabs" do
    assert_equal 2, FormTabResource.form_tabs.length
    assert_equal :personal, FormTabResource.form_tabs.first.name
    assert_equal "Personal", FormTabResource.form_tabs.first.label
    assert_equal :contact, FormTabResource.form_tabs.last.name
    assert_equal "Contact Info", FormTabResource.form_tabs.last.label
  end

  test "form_tab collects attribute names" do
    personal_tab = FormTabResource.form_tab_for(:personal)
    assert_includes personal_tab.attribute_names, :first_name
    assert_includes personal_tab.attribute_names, :last_name
    refute_includes personal_tab.attribute_names, :email

    contact_tab = FormTabResource.form_tab_for(:contact)
    assert_includes contact_tab.attribute_names, :email
    refute_includes contact_tab.attribute_names, :first_name
  end

  test "form_tab_for returns nil for unknown tab" do
    assert_nil FormTabResource.form_tab_for(:nonexistent)
  end

  test "tab_permitted_params returns correct params for tab" do
    permitted = FormTabResource.tab_permitted_params(:personal)
    assert_includes permitted, :first_name
    assert_includes permitted, :last_name
    refute_includes permitted, :email
  end

  test "tab_permitted_params returns empty array for unknown tab" do
    assert_equal [], FormTabResource.tab_permitted_params(:nonexistent)
  end

  test "form_tabs are not inherited" do
    subclass = Class.new(FormTabResource)
    assert_equal [], subclass.form_tabs
  end

  test "section registers sections" do
    assert_equal 2, FormSectionResource.form_sections.length
    assert_equal :general, FormSectionResource.form_sections.first.name
    assert_equal "General", FormSectionResource.form_sections.first.label
    assert_equal :contact, FormSectionResource.form_sections.last.name
    assert_equal "Contact Info", FormSectionResource.form_sections.last.label
  end

  test "section collects attribute names" do
    general_section = FormSectionResource.form_sections.find { |s| s.name == :general }
    assert_includes general_section.attribute_names, :first_name
    assert_includes general_section.attribute_names, :last_name
    refute_includes general_section.attribute_names, :email

    contact_section = FormSectionResource.form_sections.find { |s| s.name == :contact }
    assert_includes contact_section.attribute_names, :email
    refute_includes contact_section.attribute_names, :first_name
  end

  test "form_sections are not inherited" do
    subclass = Class.new(FormSectionResource)
    assert_equal [], subclass.form_sections
  end
end
