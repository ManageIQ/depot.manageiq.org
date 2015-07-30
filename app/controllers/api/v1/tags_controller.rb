class Api::V1::TagsController < ApplicationController
  def index
    @tags = Tag.where("name ILIKE :search", search: "#{params['q']}%").limit(5).all
    @platforms = SupportedPlatform.where("name ILIKE :search", search: "#{params['q']}%").limit(5).all
    @defaults = Tag::DEFAULT_TAGS.select { |t| t =~ /^#{params[:q]}/i }
    render json: @tags.map(&:name) + @platforms.map(&:name) + @defaults
  end
end
