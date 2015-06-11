class Api::V1::TagsController < ApplicationController
  def index
    @tags = Tag.where("name ILIKE :search", search: "#{params['q']}%").limit(5).all
    render json: @tags.map(&:name)
  end
end
