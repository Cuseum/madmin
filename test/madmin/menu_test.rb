require "test_helper"

class MenuTest < ActiveSupport::TestCase
  setup do
    @menu = Madmin::Menu.new
  end

  test "add creates a top-level menu item" do
    @menu.add(label: "Users", url: "/madmin/users")
    assert_equal 1, @menu.items.length
    item = @menu.items.first
    assert_equal "Users", item.label
    assert_equal "/madmin/users", item.url
  end

  test "add creates a nested menu item under a parent" do
    @menu.add(label: "Users", url: "/madmin/users", parent: "People")
    assert_equal 1, @menu.items.length
    parent = @menu.items.first
    assert_equal "People", parent.label
    assert_nil parent.url
    assert_equal 1, parent.items.length
    assert_equal "Users", parent.items.first.label
  end

  test "items are sorted by position" do
    @menu.add(label: "Z Item", url: "/z", position: 10)
    @menu.add(label: "A Item", url: "/a", position: 1)
    assert_equal "A Item", @menu.items.first.label
    assert_equal "Z Item", @menu.items.last.label
  end

  test "items with the same position are sorted alphabetically" do
    @menu.add(label: "Zebra", url: "/z", position: 99)
    @menu.add(label: "Apple", url: "/a", position: 99)
    assert_equal "Apple", @menu.items.first.label
    assert_equal "Zebra", @menu.items.last.label
  end

  test "reset clears all menu items" do
    @menu.add(label: "Users", url: "/madmin/users")
    assert_equal 1, @menu.items.length
    @menu.reset
    assert_equal 0, @menu.items.length
  end

  test "before_render block is called during render" do
    called = false
    @menu.before_render { called = true }
    @menu.render { |_item| }
    assert called
  end

  test "render yields items from resources that have menu options" do
    visible = Module.new do
      def self.menu_options
        {label: "Visible", url: "/visible"}
      end
    end

    Madmin.stub :resources, [visible] do
      labels = []
      @menu.render { |item| labels << item.label }
      assert_equal ["Visible"], labels
    end
  end

  test "render skips resources with menu false" do
    hidden = Module.new do
      def self.menu_options
        false
      end
    end

    Madmin.stub :resources, [hidden] do
      labels = []
      @menu.render { |item| labels << item.label }
      assert_empty labels
    end
  end

  test "render skips resources with menu hidden: true" do
    resource = Class.new(Madmin::Resource) do
      menu hidden: true
    end

    assert_equal false, resource.menu_options

    Madmin.stub :resources, [resource] do
      labels = []
      @menu.render { |item| labels << item.label }
      assert_empty labels
    end
  end
end
