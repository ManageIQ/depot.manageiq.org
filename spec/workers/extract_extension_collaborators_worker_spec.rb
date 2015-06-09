require "spec_helper"

describe ExtractExtensionCollaboratorsWorker do
  let(:extension_id) { 123 }

  let(:extension) { double(:extension, id: extension_id, github_repo: "cvincent/test") }
  let(:octokit) { double(:octokit) }

  let(:contributors) do
    [
      { login: "test1", contributions: 1 },
      { login: "test2", contributions: 0 },
      { login: "test3", contributions: 99 }
    ]
  end

  before do
    allow(Extension).to receive(:find).with(extension_id) { extension }

    allow(Rails.configuration).to receive(:octokit) { octokit }
    allow(octokit).to receive(:contributors).with("cvincent/test", nil, page: 1) { contributors }

    stub_const("ExtractExtensionCollaboratorWorker", Class.new)
    allow(ExtractExtensionCollaboratorWorker).to receive(:perform_async)

    allow(ExtractExtensionCollaboratorsWorker).to receive(:perform_async)
  end

  it "adds each collaborator returned with at least one commit" do
    expect(ExtractExtensionCollaboratorWorker).to receive(:perform_async).with(extension_id, contributors[0][:login])
    expect(ExtractExtensionCollaboratorWorker).to receive(:perform_async).with(extension_id, contributors[2][:login])
    subject.perform(extension_id)
  end

  it "skips collaborators with zero commits" do
    expect(ExtractExtensionCollaboratorWorker).not_to receive(:perform_async).with(extension, contributors[1][:login])
    subject.perform(extension_id)
  end

  it "calls itself for the next page if there were any collaborators returned" do
    expect(ExtractExtensionCollaboratorsWorker).to receive(:perform_async).with(extension_id, 2)
    subject.perform(extension_id)
  end

  it "does not call itself for the next page if there were no collaborators returned" do
    allow(octokit).to receive(:contributors).with("cvincent/test", nil, page: 1) { [] }
    expect(ExtractExtensionCollaboratorsWorker).not_to receive(:perform_async).with(extension_id, 2)
    subject.perform(extension_id)
  end
end
