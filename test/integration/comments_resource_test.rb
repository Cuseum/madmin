require "test_helper"

class CommentsResourceTest < ActionDispatch::IntegrationTest
  test "can see the comments index" do
    get madmin_comments_path
    assert_response :success
  end

  test "can see the comments new" do
    get new_madmin_comment_path
    assert_response :success
  end

  test "can see the comments edit" do
    get edit_madmin_comment_path(comments(:one))
    assert_response :success
  end

  test "new page renders form sections defined inside form block" do
    get new_madmin_comment_path
    assert_response :success
    assert_select "div.form-section", count: 2
    assert_select "h3.form-section-title", text: "Content"
    assert_select "h3.form-section-title", text: "Associations"
  end

  test "edit page renders form sections defined inside form block" do
    get edit_madmin_comment_path(comments(:one))
    assert_response :success
    assert_select "div.form-section", count: 2
    assert_select "h3.form-section-title", text: "Content"
    assert_select "h3.form-section-title", text: "Associations"
  end

  test "form renders attributes within their sections" do
    get edit_madmin_comment_path(comments(:one))
    assert_response :success
    assert_select "textarea[name='comment[body]']"
  end
end
