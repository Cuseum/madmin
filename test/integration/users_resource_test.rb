require "test_helper"

class UsersResourceTest < ActionDispatch::IntegrationTest
  test "can see the users index" do
    get madmin_users_path
    assert_response :success
  end

  test "can see the users new" do
    get new_madmin_user_path
    assert_response :success
  end

  test "can visit new with query params to prefill values" do
    get new_madmin_user_path(user: {first_name: "Chris"})
    assert_select "input[name='user[first_name]'][value=?]", "Chris"
  end

  test "can create user" do
    assert_difference "User.count" do
      post madmin_users_path, params: {user: {first_name: "Updated", password: "password", password_confirmation: "password"}}
      assert_response :redirect
    end
  end

  test "can see the users show" do
    get madmin_user_path(users(:one))
    assert_response :success
  end

  test "show uses translated attribute name when no label option is provided" do
    get madmin_user_path(users(:one))
    assert_select "th.label", text: "Given Name"
  end

  test "can see the users edit" do
    get edit_madmin_user_path(users(:one))
    assert_response :success
  end

  test "can update user" do
    user = users(:one)
    put madmin_user_path(user), params: {user: {first_name: "Updated"}}
    assert_response :redirect
    assert_equal "Updated", user.reload.first_name
  end

  test "can delete user" do
    assert_difference "User.count", -1 do
      delete madmin_user_path(users(:one))
      assert_response :redirect
    end
  end

  test "edit page shows form tab nav when form_tabs are defined" do
    get edit_madmin_user_path(users(:one))
    assert_response :success
    assert_select "nav.form-tabs-nav"
    assert_select "nav.form-tabs-nav a", text: "General"
    assert_select "nav.form-tabs-nav a", text: "Personal"
    assert_select "nav.form-tabs-nav a", text: "Settings"
  end

  test "edit page General link is active when no tab param" do
    get edit_madmin_user_path(users(:one))
    assert_select "nav.form-tabs-nav a.active", text: "General"
    assert_select "nav.form-tabs-nav a:not(.active)", text: "Personal"
    assert_select "nav.form-tabs-nav a:not(.active)", text: "Settings"
  end

  test "edit page active tab link matches current tab param" do
    get edit_madmin_user_path(users(:one), tab: :personal)
    assert_select "nav.form-tabs-nav a.active", text: "Personal"
    assert_select "nav.form-tabs-nav a:not(.active)", text: "General"
    assert_select "nav.form-tabs-nav a:not(.active)", text: "Settings"
  end

  test "edit page with tab param renders tab-specific form" do
    get edit_madmin_user_path(users(:one), tab: :personal)
    assert_response :success
    assert_select "input[name='user[first_name]']"
    assert_select "input[name='tab'][value='personal']", count: 1
    assert_select "input[name='user[language]']", count: 0
  end

  test "update with tab param only saves tab attributes and redirects back to tab" do
    user = users(:one)
    put madmin_user_path(user), params: {user: {first_name: "TabUpdated"}, tab: :personal}
    assert_response :redirect
    assert_redirected_to edit_madmin_user_path(user, tab: :personal)
    assert_equal "TabUpdated", user.reload.first_name
  end

  test "update with unknown tab falls back to regular permitted params" do
    user = users(:one)
    put madmin_user_path(user), params: {user: {first_name: "FallbackUpdated"}, tab: :nonexistent}
    assert_response :redirect
    assert_redirected_to madmin_user_path(user)
    assert_equal "FallbackUpdated", user.reload.first_name
  end

  test "edit page with tab param renders sections inside tab" do
    get edit_madmin_user_path(users(:one), tab: :personal)
    assert_response :success
    assert_select "div.form-section", count: 1
    assert_select "h3.form-section-title", text: "Name"
    assert_select "input[name='user[first_name]']"
  end

end
