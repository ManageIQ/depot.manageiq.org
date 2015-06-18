require "spec_helper"

describe CreateExtension do
  let(:params) { { name: "asdf", description: "desc", github_url: "cvincent/test", tag_tokens: "tag1, tag2", compatible_platforms: ["", "p1", "p2"] } }
  let(:user) { double(:user, github_account: github_account, octokit: github) }
  let(:github_account) { double(:github_account, username: "some_user") }
  let(:github) { double(:github) }

  let(:extension) do
    double(:extension,
      id: 123,
      valid?: true,
      save: true,
      github_repo: "cvincent/test",
      errors: errors
    )
  end

  let(:errors) { double(:errors) }
  let(:taggings) { double(:taggings) }

  subject { CreateExtension.new(params, user) }

  before do
    allow(Extension).to receive(:new) { extension }
    allow(extension).to receive(:owner=).with(user)
    allow(extension).to receive(:taggings) { taggings }
    allow(taggings).to receive(:add)
    allow(github).to receive(:collaborator?).with("cvincent/test", "some_user") { true }
    stub_const("CollectExtensionMetadataWorker", Class.new)
    allow(CollectExtensionMetadataWorker).to receive(:perform_async)
    allow(SetupExtensionWebHooksWorker).to receive(:perform_async)
  end

  it "saves a valid extension, returning the extension" do
    expect(extension).to receive(:owner=).with(user)
    expect(extension).to receive(:save)
    expect(subject.process!).to be(extension)
  end

  it "adds tags" do
    expect(taggings).to receive(:add).with("tag1")
    expect(taggings).to receive(:add).with("tag2")
    expect(subject.process!).to be(extension)
  end

  it "kicks off a worker to gather metadata about the valid extension" do
    expect(CollectExtensionMetadataWorker).to receive(:perform_async).with(123, ["p1", "p2"])
    expect(subject.process!).to be(extension)
  end

  it "kicks off a worker to set up the repo's web hook for updates" do
    expect(SetupExtensionWebHooksWorker).to receive(:perform_async).with(123)
    expect(subject.process!).to be(extension)
  end

  it "does not save an invalid extension, returning the extension" do
    allow(extension).to receive(:valid?) { false }
    expect(extension).not_to receive(:save)
    expect(subject.process!).to be(extension)
  end

  it "does not check the repo collaborators if the extension is invalid" do
    allow(extension).to receive(:valid?) { false }
    expect(github).not_to receive(:collaborator?)
    expect(subject.process!).to be(extension)
  end

  it "does not save and adds an error if the user is not a collaborator in the repo" do
    allow(github).to receive(:collaborator?).with("cvincent/test", "some_user") { false }
    expect(extension).not_to receive(:save)
    expect(errors).to receive(:[]=).with(:github_url, I18n.t("extension.github_url_format_error"))
    expect(subject.process!).to be(extension)
  end

  it "does not save and adds an error if the repo is invalid" do
    allow(github).to receive(:collaborator?).with("cvincent/test", "some_user").and_raise(ArgumentError)
    expect(extension).not_to receive(:save)
    expect(errors).to receive(:[]=).with(:github_url, I18n.t("extension.github_url_format_error"))
    expect(subject.process!).to be(extension)
  end
end
