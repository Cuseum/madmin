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
    assert_select "h3.form-section-title", text: "Statistics"
    assert_select "input[name='post[post_stat_attributes][drafts_saved]']"
    assert_select "input[name='post[post_stat_attributes][keywords]']"
    assert_select "[data-controller='nested-form']"
  end

  test "edit page renders nested_has_many inside nested_has_one without crashing" do
    get edit_madmin_post_path(posts(:one))
    assert_response :success
    assert_select "[data-controller='nested-form']"
    assert_select "a", text: "+ Add new"
    assert_select "textarea[name='post[post_stat_attributes][comments_attributes][NEW_RECORD][body]']"
  end

  test "edit page renders arbre form with row/col for nested_has_one resource" do
    # Temporarily give PostStatResource an arbre form block with row/col so we
    # can verify the nested_has_one view routes through render_arbre when
    # form_block is set, producing the grid markup.
    original_block = PostStatResource.form_block
    PostStatResource.form_block = proc do
      row do
        col { attribute :drafts_saved }
        col { attribute :keywords }
      end
    end

    get edit_madmin_post_path(posts(:one))
    assert_response :success
    assert_select "div.form-row"
    assert_select "input[name='post[post_stat_attributes][drafts_saved]']"
    assert_select "input[name='post[post_stat_attributes][keywords]']"
  ensure
    PostStatResource.form_block = original_block
  end

  test "row and col helpers apply custom CSS classes" do
    original_block = PostStatResource.form_block
    PostStatResource.form_block = proc do
      row(class: "custom-row") do
        col(class: "custom-col") { attribute :drafts_saved }
      end
    end

    get edit_madmin_post_path(posts(:one))
    assert_response :success
    assert_select "div.form-row.custom-row"
    assert_select "div.form-col.custom-col"
  ensure
    PostStatResource.form_block = original_block
  end
end
