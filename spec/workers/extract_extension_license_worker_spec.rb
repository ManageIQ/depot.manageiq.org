require "spec_helper"

describe ExtractExtensionLicenseWorker do
  let(:extension_id) { 123 }

  let(:extension) { double(:extension, github_repo: "cvincent/test", octokit: octokit) }
  let(:octokit) { double(:octokit) }

  subject { ExtractExtensionLicenseWorker.new }

  before do
    stub_const("Extension", Class.new)
    allow(Extension).to receive(:find).with(extension_id) { extension }
  end

  it "updates the extension with the license if one is present" do
    allow(octokit).to receive(:repo).with("cvincent/test", accept: "application/vnd.github.drax-preview+json") do
      { license: { key: "mit" } }
    end

    allow(octokit).to receive(:license).with("mit", accept: "application/vnd.github.drax-preview+json") do
      { name: "MIT", body: "What's up" }
    end

    expect(extension).to receive(:update_attributes).with(license_name: "MIT", license_text: "What's up")

    subject.perform(extension_id)
  end

  it "doesn't update the extension if no license is found" do
    allow(octokit).to receive(:repo).with("cvincent/test", accept: "application/vnd.github.drax-preview+json") do
      { license: nil }
    end

    expect(extension).not_to receive(:update_attributes)
    subject.perform(extension_id)
  end
end
