class Api::V1::ExtensionsController < Api::V1Controller
  before_filter :init_params, only: [:index, :search]
  before_filter :assign_extension, only: [:show, :foodcritic, :contingent]

  #
  # GET /api/v1/extensions
  #
  # Return all Extensions. Defaults to 10 at a time, starting at the first
  # Extension when sorted alphabetically. The max number of Extensions that can be
  # returned is 100.
  #
  # Pass in the start and items params to specify the index at which to start
  # and how many to return. You can pass in an order param to specify how
  # you'd like the the collection ordered. Possible values are
  # recently_updated, recently_added, most_downloaded, most_followed. Finally,
  # you can pass in a user param to only show extensions that are owned by
  # a specific username.
  #
  # @example
  #   GET /api/v1/extensions?start=5&items=15
  #   GET /api/v1/extensions?order=recently_updated
  #   GET /api/v1/extensions?user=timmy
  #
  def index
    @total = Extension.count
    @extensions = Extension.index(order: @order, limit: @items, start: @start)

    if params[:user]
      @extensions = @extensions.owned_by(params[:user])
    end
  end

  #
  # GET /api/v1/extensions/:extension
  #
  # Return the specified extension. If it does not exist, return a 404.
  #
  # @example
  #   GET /api/v1/extensions/redis
  #
  def show
    @extension_versions_urls = @extension.sorted_extension_versions.map do |version|
      api_v1_extension_version_url(@extension, version)
    end
  end

  #
  # GET /api/v1/search?q=QUERY
  #
  # Return extensions with a name that contains the specified query. Takes the
  # +q+ parameter for the query. It also handles the start and items parameters
  # for specify where to start the search and how many items to return. Start
  # defaults to 0. Items defaults to 10. Items has an upper limit of 100.
  #
  # @example
  #   GET /api/v1/search?q=redis
  #   GET /api/v1/search?q=redis&start=3&items=5
  #
  def search
    @results = Extension.search(
      params.fetch(:q, nil)
    ).offset(@start).limit(@items)

    @total = @results.count(:all)
  end

  private

  def assign_extension
    @extension = Extension.with_name(params[:extension]).
      includes(:extension_versions).first!
  end
end
