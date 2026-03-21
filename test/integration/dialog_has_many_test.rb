require "test_helper"

class DialogHasManyTest < ActionDispatch::IntegrationTest
  test "edit page in dialog mode renders turbo-frame with form" do
    get edit_madmin_comment_path(comments(:one), dialog: 1, frame_id: "madmin-dialog-frame-comments")
    assert_response :success
    assert_select "turbo-frame[id='madmin-dialog-frame-comments']"
    assert_select ".dialog-header h3"
    assert_select ".dialog-close"
  end

  test "edit page in dialog mode sanitizes frame_id to safe characters" do
    get edit_madmin_comment_path(comments(:one), dialog: 1, frame_id: "madmin-dialog-frame-<script>alert(1)</script>")
    assert_response :success
    # The malicious characters are stripped; only alphanumerics, hyphens, underscores remain
    assert_no_match(/<script>/, response.body)
    assert_select "turbo-frame[id='madmin-dialog-frame-scriptalert1script']"
  end

  test "edit page without dialog param renders normal page" do
    get edit_madmin_comment_path(comments(:one))
    assert_response :success
    assert_select "header.header"
    assert_no_select "turbo-frame[id*='madmin-dialog-frame']"
  end

  test "edit page in dialog mode form is turbo-enabled (no data-turbo=false)" do
    get edit_madmin_comment_path(comments(:one), dialog: 1, frame_id: "madmin-dialog-frame-comments")
    assert_response :success
    # The form inside the dialog should not have data-turbo="false" (which local: true adds)
    assert_select "turbo-frame form[data-turbo='false']", count: 0
  end

  test "dialog mode uses fallback frame id when frame_id is missing" do
    get edit_madmin_comment_path(comments(:one), dialog: 1)
    assert_response :success
    assert_select "turbo-frame[id='madmin-dialog-frame']"
  end
end
