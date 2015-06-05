require "spec_helper"

describe ExtractExtensionVersionWorker do
  let(:extension_id) { 123 }
  let(:tag) { "1.0" }

  let(:extension) { double(:extension, id: extension_id, github_repo: "cvincent/test", extension_versions: versions) }
  let(:versions) { double(:versions) }
  let(:octokit) { double(:octokit) }

  subject { ExtractExtensionVersionWorker.new }

  before do
    stub_const("Extension", Class.new)
    allow(Extension).to receive(:find).with(extension_id) { extension }
    allow(Rails.configuration).to receive(:octokit) { octokit }
  end

  it "creates a README based on the one returned from GitHub" do
    allow(octokit).to receive(:readme).with("cvincent/test", ref: "1.0") do
      { name: "README.md", content: Base64.encode64("Hello world!") }
    end

    expect(versions).to receive(:create).with(readme: "Hello world!", readme_extension: "md")

    subject.perform(extension_id, tag)
  end

  it "creates a default README if one is missing" do
    allow(octokit).to receive(:readme).with("cvincent/test", ref: "1.0").and_raise(Octokit::NotFound)

    expect(versions).to receive(:create).with(readme: "No readme found!", readme_extension: "txt")

    subject.perform(extension_id, tag)
  end

  it "fails silently if the tag is not a well-formatted SemVer" do
    expect {
      subject.perform(extension_id, "v1.0")
    }.not_to raise_error
  end
end
