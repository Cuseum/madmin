require "test_helper"

class PostsResourceTest < ActionDispatch::IntegrationTest
  test "edit page renders nested_has_one inputs" do
    get edit_madmin_post_path(posts(:one))
    assert_response :success
    assert_select "input[name*='post_stat_attributes']"
  end

  test "creates post_stat via nested_has_one attributes" do
    post_record = posts(:two)
    assert_nil post_record.post_stat

    put madmin_post_path(post_record), params: {
      post: {
        post_stat_attributes: {
          drafts_saved: 5,
          keywords: "rails, ruby"
        }
      }
    }

    assert_response :redirect
    post_record.reload
    assert_not_nil post_record.post_stat
    assert_equal 5, post_record.post_stat.drafts_saved
    assert_equal "rails, ruby", post_record.post_stat.keywords
  end

  test "updates existing post_stat via nested_has_one attributes" do
    post_record = posts(:one)
    stat = post_stats(:one)
    assert_equal 3, stat.drafts_saved

    put madmin_post_path(post_record), params: {
      post: {
        post_stat_attributes: {
          id: stat.id,
          drafts_saved: 10,
          keywords: "updated keywords"
        }
      }
    }

    assert_response :redirect
    assert_equal 10, stat.reload.drafts_saved
    assert_equal "updated keywords", stat.keywords
  end

  test "destroys post_stat via nested_has_one _destroy attribute" do
    post_record = posts(:one)
    stat = post_stats(:one)

    put madmin_post_path(post_record), params: {
      post: {
        post_stat_attributes: {
          id: stat.id,
          _destroy: "1"
        }
      }
    }

    assert_response :redirect
    assert_nil PostStat.find_by(id: stat.id)
  end

  test "edit page renders sections from nested resource form definition" do
    get edit_madmin_post_path(posts(:one))
    assert_response :success
    assert_select "div.form-section", count: 1
    assert_select "h3.form-section-title", text: "Statistics"
    assert_select "input[name='post[post_stat_attributes][drafts_saved]']"
    assert_select "input[name='post[post_stat_attributes][keywords]']"
  end
end
