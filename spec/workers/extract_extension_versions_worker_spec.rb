require "spec_helper"

describe ExtractExtensionVersionsWorker do
  let(:extension_id) { 123 }
  let(:compatible_platforms) { ["1", "2"] }

  let(:extension) { double(:extension, id: extension_id, github_repo: "cvincent/test", octokit: octokit) }
  let(:octokit) { double(:octokit) }

  subject { ExtractExtensionVersionsWorker.new }

  before do
    stub_const("Extension", Class.new)
    allow(Extension).to receive(:find).with(extension_id) { extension }
    stub_const("ExtractExtensionVersionWorker", Class.new)
  end

  it "kicks off a worker for each extension version found" do
    allow(octokit).to receive(:tags).with("cvincent/test") do
      [
        { name: "1.0" },
        { name: "1.2" }
      ]
    end

    expect(ExtractExtensionVersionWorker).to receive(:perform_async).with(123, "1.0", compatible_platforms)
    expect(ExtractExtensionVersionWorker).to receive(:perform_async).with(123, "1.2", compatible_platforms)

    subject.perform(extension_id, compatible_platforms)
  end
end
