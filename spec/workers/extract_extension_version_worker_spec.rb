require "spec_helper"

describe ExtractExtensionVersionWorker do
  let(:extension_id) { 123 }
  let(:tag) { "1.0" }
  let(:compatible_platforms) { ["1", "2"] }

  let(:extension) { double(:extension, id: extension_id, github_repo: "cvincent/test", extension_versions: versions, octokit: octokit) }
  let(:versions) { double(:versions) }
  let(:octokit) { double(:octokit, readme: { name: "README.md", content: "hi" }) }
  let(:version) { double(:version, extension_version_platforms: evp_assoc) }
  let(:evp_assoc) { double(:evp_assoc) }

  let(:supported_platforms) do
    [
      double(:p1, id: 1),
      double(:p2, id: 2)
    ]
  end

  subject { ExtractExtensionVersionWorker.new }

  before do
    stub_const("Extension", Class.new)
    allow(Extension).to receive(:find).with(extension_id) { extension }
    allow(SupportedPlatform).to receive(:find).with(compatible_platforms) { supported_platforms }
    allow(versions).to receive(:create!) { version }
    allow(evp_assoc).to receive(:create)
  end

  it "creates a README based on the one returned from GitHub" do
    allow(octokit).to receive(:readme).with("cvincent/test", ref: "1.0") do
      { name: "README.md", content: Base64.encode64("Hello world!") }
    end

    expect(versions).to receive(:create!).with(version: "1.0", readme: "Hello world!", readme_extension: "md")

    subject.perform(extension_id, tag, compatible_platforms)
  end

  it "creates a default README if one is missing" do
    allow(octokit).to receive(:readme).with("cvincent/test", ref: "1.0").and_raise(Octokit::NotFound)

    expect(versions).to receive(:create!).with(version: "1.0", readme: "No readme found!", readme_extension: "txt")

    subject.perform(extension_id, tag, compatible_platforms)
  end

  it "links the version to its supported platforms" do
    expect(evp_assoc).to receive(:create).with(supported_platform_id: 1)
    expect(evp_assoc).to receive(:create).with(supported_platform_id: 2)
    subject.perform(extension_id, tag, compatible_platforms)
  end

  it "fails silently if the tag is not a well-formatted SemVer" do
    expect {
      subject.perform(extension_id, "v1.0", compatible_platforms)
    }.not_to raise_error
  end
end
