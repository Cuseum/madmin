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

  form do
    section :general do
      attribute :first_name
      attribute :last_name
    end

    section :contact, label: "Contact Info" do
      attribute :email
    end
  end
end

class FormSectionWithDescriptionResource < Madmin::Resource
  model User

  form do
    section :general, description: "Basic information" do
      attribute :first_name
      attribute :last_name
    end

    section :contact, label: "Contact Info", description: -> { "Current time: #{Time.current.year}" } do
      attribute :email
    end
  end
end

class MixedFormResource < Madmin::Resource
  model User

  form do
    section :details do
      attribute :first_name
      attribute :last_name
    end

    attribute :email
  end
end

class FormTabWithSectionResource < Madmin::Resource
  model User

  form_tab :details do
    section :personal do
      attribute :first_name
      attribute :last_name
    end

    attribute :email
  end
end

class HiddenMenuResource < Madmin::Resource
  model User
  menu hidden: true
end

class FormRowResource < Madmin::Resource
  model User

  form do
    attribute :email

    row do
      col { attribute :first_name }
      col { attribute :last_name }
    end
  end
end

class FormTabWithRowResource < Madmin::Resource
  model User

  form_tab :details do
    attribute :email

    row do
      col { attribute :first_name }
      col { attribute :last_name }
    end
  end
end

class FormSectionWithRowResource < Madmin::Resource
  model User

  form do
    section :details do
      attribute :email

      row do
        col { attribute :first_name }
        col { attribute :last_name }
      end
    end
  end
end

class ResourceTest < ActiveSupport::TestCase
  test "menu_options returns false when menu hidden: true" do
    assert_equal false, HiddenMenuResource.menu_options
  end

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

  test "section description defaults to nil" do
    assert_nil FormSectionResource.form_sections.first.description
  end

  test "section accepts a string description" do
    general_section = FormSectionWithDescriptionResource.form_sections.find { |s| s.name == :general }
    assert_equal "Basic information", general_section.description
  end

  test "section accepts a callable description for dynamic content" do
    contact_section = FormSectionWithDescriptionResource.form_sections.find { |s| s.name == :contact }
    assert_respond_to contact_section.description, :call
    assert_includes contact_section.description.call, Time.current.year.to_s
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

  test "section inside form makes attributes visible in form context" do
    assert FormSectionResource.attributes[:first_name].field.visible?(:form)
    assert FormSectionResource.attributes[:last_name].field.visible?(:form)
    assert FormSectionResource.attributes[:email].field.visible?(:form)
  end

  test "form_sections are not inherited" do
    subclass = Class.new(FormSectionResource)
    assert_equal [], subclass.form_sections
  end

  test "form_items preserves definition order with sections before attributes" do
    items = MixedFormResource.form_items
    assert_equal 2, items.length
    assert_kind_of Madmin::Resource::FormSection, items.first
    assert_equal :details, items.first.name
    assert_equal :email, items.last
  end

  test "form_items preserves definition order with sections after attributes" do
    resource = Class.new(Madmin::Resource) do
      model User
      form do
        attribute :email
        section :details do
          attribute :first_name
        end
      end
    end
    items = resource.form_items
    assert_equal 2, items.length
    assert_equal :email, items.first
    assert_kind_of Madmin::Resource::FormSection, items.last
    assert_equal :details, items.last.name
  end

  test "form_tab with section registers section in form_sections" do
    assert_equal 1, FormTabWithSectionResource.form_sections.length
    assert_equal :personal, FormTabWithSectionResource.form_sections.first.name
  end

  test "form_tab with section collects flat attribute_names including section attributes" do
    tab = FormTabWithSectionResource.form_tab_for(:details)
    assert_includes tab.attribute_names, :first_name
    assert_includes tab.attribute_names, :last_name
    assert_includes tab.attribute_names, :email
  end

  test "form_tab with section stores FormSection in tab_items" do
    tab = FormTabWithSectionResource.form_tab_for(:details)
    assert_equal 2, tab.tab_items.length
    assert_kind_of Madmin::Resource::FormSection, tab.tab_items.first
    assert_equal :personal, tab.tab_items.first.name
    assert_equal :email, tab.tab_items.last
  end

  test "form_tab with section tab_items preserves definition order" do
    resource = Class.new(Madmin::Resource) do
      model User
      form_tab :mixed do
        attribute :email
        section :name do
          attribute :first_name
        end
      end
    end
    tab = resource.form_tab_for(:mixed)
    assert_equal 2, tab.tab_items.length
    assert_equal :email, tab.tab_items.first
    assert_kind_of Madmin::Resource::FormSection, tab.tab_items.last
  end

  test "tab_permitted_params includes attributes from sections inside form_tab" do
    permitted = FormTabWithSectionResource.tab_permitted_params(:details)
    assert_includes permitted, :first_name
    assert_includes permitted, :last_name
    assert_includes permitted, :email
  end

  test "row creates a FormRow in form_items" do
    items = FormRowResource.form_items
    assert_equal 2, items.length
    assert_equal :email, items.first
    assert_kind_of Madmin::Resource::FormRow, items.last
  end

  test "row contains the correct number of cols" do
    row = FormRowResource.form_items.last
    assert_equal 2, row.cols.size
  end

  test "col collects attribute names" do
    row = FormRowResource.form_items.last
    assert_kind_of Madmin::Resource::FormCol, row.cols.first
    assert_includes row.cols.first.attribute_names, :first_name
    assert_kind_of Madmin::Resource::FormCol, row.cols.last
    assert_includes row.cols.last.attribute_names, :last_name
  end

  test "row makes attributes visible in form context" do
    assert FormRowResource.attributes[:first_name].field.visible?(:form)
    assert FormRowResource.attributes[:last_name].field.visible?(:form)
    assert FormRowResource.attributes[:email].field.visible?(:form)
  end

  test "row attributes are included in permitted_params" do
    permitted = FormRowResource.permitted_params
    assert_includes permitted, :first_name
    assert_includes permitted, :last_name
    assert_includes permitted, :email
  end

  test "row inside form_tab creates a FormRow in tab_items" do
    tab = FormTabWithRowResource.form_tab_for(:details)
    assert_equal 2, tab.tab_items.length
    assert_equal :email, tab.tab_items.first
    assert_kind_of Madmin::Resource::FormRow, tab.tab_items.last
  end

  test "row inside form_tab contains the correct number of cols" do
    tab = FormTabWithRowResource.form_tab_for(:details)
    row = tab.tab_items.last
    assert_equal 2, row.cols.size
  end

  test "row inside form_tab collects flat attribute_names including col attributes" do
    tab = FormTabWithRowResource.form_tab_for(:details)
    assert_includes tab.attribute_names, :email
    assert_includes tab.attribute_names, :first_name
    assert_includes tab.attribute_names, :last_name
  end

  test "row inside form_tab attributes are included in tab_permitted_params" do
    permitted = FormTabWithRowResource.tab_permitted_params(:details)
    assert_includes permitted, :email
    assert_includes permitted, :first_name
    assert_includes permitted, :last_name
  end

  test "row inside section creates a FormRow in section_items" do
    section = FormSectionWithRowResource.form_sections.find { |s| s.name == :details }
    assert_equal 2, section.section_items.length
    assert_equal :email, section.section_items.first
    assert_kind_of Madmin::Resource::FormRow, section.section_items.last
  end

  test "row inside section contains the correct number of cols" do
    section = FormSectionWithRowResource.form_sections.find { |s| s.name == :details }
    row = section.section_items.last
    assert_equal 2, row.cols.size
  end

  test "row inside section collects flat attribute_names including col attributes" do
    section = FormSectionWithRowResource.form_sections.find { |s| s.name == :details }
    assert_includes section.attribute_names, :email
    assert_includes section.attribute_names, :first_name
    assert_includes section.attribute_names, :last_name
  end

  test "row inside section attributes are included in permitted_params" do
    permitted = FormSectionWithRowResource.permitted_params
    assert_includes permitted, :email
    assert_includes permitted, :first_name
    assert_includes permitted, :last_name
  end
end

class ArbreIndexResource < Madmin::Resource
  model User

  index do
    h1 { "Users" }
  end
end

class ArbreShowResource < Madmin::Resource
  model User

  show do
    para { "User details" }
  end
end

class ArbreFormResource < Madmin::Resource
  model User

  form do
    div do
      para { "Custom form content" }
    end
  end
end

class ArbreResourceTest < ActiveSupport::TestCase
  test "arbre index block is stored" do
    assert_not_nil ArbreIndexResource.index_block
  end

  test "arbre index block is a Proc" do
    assert_kind_of Proc, ArbreIndexResource.index_block
  end

  test "arbre show block is stored" do
    assert_not_nil ArbreShowResource.show_block
  end

  test "arbre show block is a Proc" do
    assert_kind_of Proc, ArbreShowResource.show_block
  end

  test "arbre form block is stored" do
    assert_not_nil ArbreFormResource.form_block
  end

  test "arbre form block is a Proc" do
    assert_kind_of Proc, ArbreFormResource.form_block
  end

  test "attribute-style index block does not store an arbre block" do
    assert_nil BlockStyleResource.index_block
  end

  test "attribute-style show block does not store an arbre block" do
    assert_nil BlockStyleResource.show_block
  end

  test "attribute-style form block does not store an arbre block" do
    assert_nil BlockStyleResource.form_block
  end

  test "arbre index block renders correct html" do
    html = Arbre::Context.new({}, nil, &ArbreIndexResource.index_block).to_s
    assert_includes html, "<h1>Users</h1>"
  end

  test "arbre show block renders correct html" do
    html = Arbre::Context.new({}, nil, &ArbreShowResource.show_block).to_s
    assert_includes html, "<p>User details</p>"
  end

  test "arbre form block renders correct html" do
    html = Arbre::Context.new({}, nil, &ArbreFormResource.form_block).to_s
    assert_includes html, "<div>"
    assert_includes html, "<p>Custom form content</p>"
  end

  test "arbre blocks are not inherited" do
    subclass = Class.new(ArbreIndexResource)
    assert_nil subclass.index_block
  end
end
