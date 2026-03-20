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

  test "form_block renders section description when section contains row/col" do
    # When row/col appear inside a section the whole form block is stored as
    # form_block and rendered via render_arbre.  The injected `section` method
    # must emit the proper label + description markup, including callable lambdas.
    original_block = CommentResource.form_block
    original_form_attributes = CommentResource.form_attributes

    CommentResource.form_block = proc do
      section :content, description: -> { "Your comment body" } do
        row do
          col { attribute :body }
        end
      end
    end
    CommentResource.form_attributes = [:body]

    get new_madmin_comment_path
    assert_response :success
    assert_select "div.form-section"
    assert_select "h3.form-section-title", text: "Content"
    assert_select "p.form-section-description", text: "Your comment body"
    assert_select "div.form-row"
  ensure
    CommentResource.form_block = original_block
    CommentResource.form_attributes = original_form_attributes
  end
end
