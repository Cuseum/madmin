class PostStat < ApplicationRecord
  belongs_to :post
  has_many :comments, as: :commentable, dependent: :destroy
  accepts_nested_attributes_for :comments, allow_destroy: true
end
