class Api::V1::MetricsController < Api::V1Controller
  #
  # GET /api/v1/metrics
  #
  # Various counters
  #
  def show
    @metrics = {
      total_extension_downloads: Extension.total_download_count,
      total_extension_versions: ExtensionVersion.count,
      total_extensions: Extension.count,
      total_follows: ExtensionFollower.count,
      total_users: User.count,
      total_hits: { '/universe' => Universe.show_hits }
    }
  end
end
