class SyncExtensionContentsAtVersionsWorker
  include Sidekiq::Worker

  def perform(extension_id, tags, compatible_platforms)
    @extension = Extension.find(extension_id)
    @tags = tags
    @tag = @tags.shift
    @compatible_platforms = SupportedPlatform.find(compatible_platforms)
    @run = CmdAtPath.new(@extension.repo_path)

    perform_next and return unless semver?

    checkout_correct_tag
    readme_body, readme_ext = fetch_readme
    version = ensure_updated_version(readme_body, readme_ext)
    set_compatible_platforms(version)
    set_last_commit(version)
    scan_files(version)
    version.save

    perform_next
  end

  private

  def perform_next
    if @tags.any?
      self.class.perform_async(@extension.id, @tags, @compatible_platforms)
    end
  end

  def semver?
    return true if @tag == "master"

    begin
      Semverse::Version.new(@tag)
      return true
    rescue Semverse::InvalidVersionFormat
      return false
    end
  end

  def checkout_correct_tag
    @run.cmd("git checkout #{@tag}")
  end

  def fetch_readme
    filename = @cmd.run("ls README*")

    if filename = filename.first
      ext = extract_readme_file_extension(filename)
      body = @cmd.run("cat #{filename}")
      return "README body here", "txt"
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
    yml_line_count = @cmd.run("find . -name '*.yml' -o -name '*.yaml' | xargs wc -l").split("\n").last || ""
    rb_line_count = @cmd.run("find . -name '*.rb' | xargs wc -l").split("\n").last || ""

    yml_line_count = yml_line_count.strip.to_i
    rb_line_count = yml_line_count.strip.to_i

    @extension.extension_versions.first_or_create(version: @tag).tap do |version|
      version.update_attributes(
        readme: readme_body,
        readme_extension: readme_ext,
        yml_line_count: yml_line_count,
        rb_line_count: rb_line_count
      )
    end
  end

  def set_compatible_platforms(version)
    version.extension_version_platforms = @compatible_platforms.map do |cp|
      version.extension_version_platforms.first_or_initialize(supported_platform_id: cp.id)
    end
  end

  def set_last_commit(version)
    commit = @cmd.run("git log HEAD^..HEAD")
    sha, author, date = *commit.split("\n")
    message = commit.split("\n\n").last.gsub("\n", " ").strip

    sha = sha.gsub("commit ", "")
    date = Time.parse(date.gsub("Date:", "").strip)

    version.last_commit_sha = sha
    version.last_commit_at = date
    version.last_commit_string = message
    version.last_commit_url = version.extension.github_url + "/commit/#{sha}"
  end

  def scan_files(version)
    version.extension_version_content_items.destroy_all
    scan_yml_files(version)
    scan_class_dirs(version)
  end

  def scan_yml_files(version)
    @cmd.run("find . -name '*.yml' -o -name '*.yaml'").split("\n").each do |path|
      body = @cmd.run("cat #{path}")
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
      end

      next if type.nil?

      @version.extension_version_content_items.first_or_create(
        name: path.gsub(/.+\//, ""),
        path: path,
        item_type: type,
        github_url: version.extension.github_url + "/blob/#{version.version}/#{path}"
      )
    end
  end

  def scan_class_dirs(version)
    @cmd.run("find . -name '*.class'").split("\n").each do |path|
      @version.extension_version_content_items.first_or_create(
        name: path.gsub(/.+\//, ""),
        path: path,
        item_type: "Class",
        github_url: version.extension.github_url + "/blob/#{version.version}/#{path}"
      )
    end
  end
end
