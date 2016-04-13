class SyncExtensionContentsAtVersionsWorker
  include Sidekiq::Worker

  def logger
    @logger ||= Logger.new("log/scan.log")
  end

  def perform(extension_id, tags, compatible_platforms = [])
    logger.info("PERFORMING: #{extension_id}, #{tags.inspect}, #{compatible_platforms.inspect}")

    Extension.transaction do
      @extension = Extension.where(id: extension_id, syncing: false).lock(true).first
      raise RuntimeError.new("Syncing already in progress.") unless @extension
      @extension.update_attribute(:syncing, true)
    end

    @tags = tags
    @tag = @tags.shift
    @compatible_platforms = compatible_platforms
    @run = CmdAtPath.new(@extension.repo_path)

    perform_next and return unless semver?

    checkout_correct_tag
    readme_body, readme_ext = fetch_readme
    logger.info "GOT README: #{readme_body}"
    version = ensure_updated_version(readme_body, readme_ext)
    set_compatible_platforms(version)
    set_last_commit(version)
    set_commit_count(version)
    scan_files(version)
    version.save

    tally_commits if @tag == "master"

    perform_next
  ensure
    @extension.update_attribute(:syncing, false) if @extension
  end

  private

  def perform_next
    if @tags.any?
      @extension.update_attribute(:syncing, false)
      self.class.perform_async(@extension.id, @tags, @compatible_platforms)
    end
  end

  def semver?
    return true if @tag == "master"

    begin
      Semverse::Version.new(@tag.gsub(/\Av/, ""))
      return true
    rescue Semverse::InvalidVersionFormat
      return false
    end
  end

  def checkout_correct_tag
    @run.cmd("git checkout #{@tag}")
    @run.cmd("git pull origin #{@tag}")
  end

  def fetch_readme
    filename = @run.cmd("ls README*").split("\n")
    logger.info filename.inspect

    if filename = filename.first
      ext = extract_readme_file_extension(filename)
      body = @run.cmd("cat '#{filename}'")
      return body, ext
    else
      return "There is no README file for this extension.", "txt"
    end
  end

  def extract_readme_file_extension(filename)
    if match = filename.match(/\.[a-zA-Z0-9]+$/)
      match[0].gsub(".", "")
    else
      "txt"
    end
  end

  def ensure_updated_version(readme_body, readme_ext)
    yml_line_count = @run.cmd("find . -name '*.yml' -o -name '*.yaml' -print0 | xargs -0 wc -l").split("\n").last || ""
    rb_line_count = @run.cmd("find . -name '*.rb' -print0 | xargs -0 wc -l").split("\n").last || ""

    yml_line_count = yml_line_count.strip.to_i
    rb_line_count = rb_line_count.strip.to_i

    @extension.extension_versions.where(version: @tag).first_or_create!.tap do |version|
      version.update_attributes(
        readme: readme_body,
        readme_extension: readme_ext,
        yml_line_count: yml_line_count,
        rb_line_count: rb_line_count
      )
    end
  end

  def set_compatible_platforms(version)
    unless version.supported_platforms.any?
      version.supported_platform_ids = @compatible_platforms
    end
  rescue PG::UniqueViolation
  end

  def set_last_commit(version)
    commit = @run.cmd("git log -1").gsub(/^Merge: [^\n]+\n/, "")
    sha, author, date = *commit.split("\n")

    unless message = commit.split("\n\n").last
      # Empty repo; no commits
      return
    end

    message = message.gsub("\n", " ").strip
    sha = sha.gsub("commit ", "")
    date = Time.parse(date.gsub("Date:", "").strip)

    version.last_commit_sha = sha
    version.last_commit_at = date
    version.last_commit_string = message
    version.last_commit_url = version.extension.github_url + "/commit/#{sha}"
  end

  def set_commit_count(version)
    version.commit_count = @run.cmd("git shortlog | grep -E '^[ ]+\\w+' | wc -l").strip.to_i
    logger.info "COMMIT COUNT: #{version.commit_count}"
  end

  def scan_files(version)
    version.extension_version_content_items.destroy_all
    logger.info("SCANNING FILES")
    scan_yml_files(version)
    scan_class_dirs(version)
  end

  def scan_yml_files(version)
    @run.cmd("find . -name '*.yml' -o -name '*.yaml'").tap { |r| logger.info("YAML FILES: #{r.inspect}") }.split("\n").each do |path|
      logger.info("SCANNING: #{path}")
      body = @run.cmd("cat '#{path}'")
      path = path.gsub("./", "")

      type = if body["MiqReport"]
        "Report"
      elsif body["MiqPolicySet"]
        "Policy"
      elsif body["MiqAlert"]
        "Alert"
      elsif body["dialog_tabs"]
        "Dialog"
      elsif body["MiqWidget"]
        "Widget"
      elsif body["CustomButtonSet"]
        "Button Set"
      end

      next if type.nil?

      logger.info version.extension_version_content_items.where(path: path).first_or_create!(
        name: path.gsub(/.+\//, ""),
        item_type: type,
        github_url: version.extension.github_url + "/blob/#{version.version}/#{CGI.escape(path)}"
      ).inspect
    end
  end

  def scan_class_dirs(version)
    @run.cmd("find . -name '*.class'").tap { |r| logger.info("RB FILES: #{r.inspect}") }.split("\n").each do |path|
      logger.info("SCANNING: #{path}")
      logger.info version.extension_version_content_items.where(path: path).first_or_create!(
        name: path.gsub(/.+\//, ""),
        item_type: "Class",
        github_url: version.extension.github_url + "/blob/#{version.version}/#{path}"
      ).inspect
    end
  end

  def tally_commits
    commits = @run.cmd("git --no-pager log --format='%H|%ad'")

    commits.split("\n").each do |c|
      sha, date = c.split("|")

      CommitSha.transaction do
        if !CommitSha.where(sha: sha).first
          CommitSha.create(sha: sha)
          DailyMetric.increment(@extension.commit_daily_metric_key, 1, date.to_date)
        end
      end
    end
  end
end

