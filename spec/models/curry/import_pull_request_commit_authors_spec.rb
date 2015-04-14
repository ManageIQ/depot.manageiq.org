require 'spec_helper'
require 'vcr_helper'

describe Curry::ImportPullRequestCommitAuthors do
  around(:each) do |example|
    VCR.use_cassette('import_unknown_pull_request_commit_authors', record: :once) do
      example.run
    end
  end

  it 'creates records for the unknown commit authors of a pull request' do
    # NOTE: This is a repository created to be in _this_ state
    repository = create(:repository, owner: 'gofullstack', name: 'paprika')
    pull_request = create(:pull_request, repository: repository)
    importer = Curry::ImportPullRequestCommitAuthors.new(pull_request)

    expect do
      importer.import_commit_authors
    end.to change(pull_request.reload.unknown_commit_authors, :count).by(2)
  end

  it 'does not duplicate existing unknown commit authors' do
    repository = create(:repository, owner: 'gofullstack', name: 'paprika')
    pull_request = create(:pull_request, repository: repository)
    importer = Curry::ImportPullRequestCommitAuthors.new(pull_request)

    expect do
      2.times { importer.import_commit_authors }
    end.to change(pull_request.reload.unknown_commit_authors, :count).by(2)
  end

  it 'imports commit authors known to have signed an ICLA' do
    # NOTE: there is implicit state at work here. The
    # import_unknown_pull_request_commit_authors VCR cassette contains a
    # response for a Pull Request with two commit authors. We set up an account
    # and an ICLA signature for one of them (brettchalupa)
    repository = create(:repository, owner: 'gofullstack', name: 'paprika')
    pull_request = create(:pull_request, repository: repository)
    importer = Curry::ImportPullRequestCommitAuthors.new(pull_request)

    user = create(:user)
    account = create(
      :account,
      user: user,
      username: 'brettchalupa',
      provider: 'github'
    )
    create(:icla_signature, user: user)

    importer.import_commit_authors

    brett = pull_request.commit_authors.with_login('brettchalupa').first!

    expect(brett).to be_authorized_to_contribute
  end

  it "does not import commit authors known to be an organization's contributors" do
    repository = create(:repository, owner: 'gofullstack', name: 'paprika')
    pull_request = create(:pull_request, repository: repository)
    importer = Curry::ImportPullRequestCommitAuthors.new(pull_request)

    user = create(:user)
    account = create(
      :account,
      user: user,
      username: 'brettchalupa',
      provider: 'github'
    )
    create(:contributor, user: user)

    expect do
      importer.import_commit_authors
    end.to change(pull_request.reload.commit_authors, :count).by(2)
  end

  it "keeps a commit author's authorized_to_contribute status up-to-date" do
    repository = create(:repository, owner: 'gofullstack', name: 'paprika')
    pull_request = create(:pull_request, repository: repository)

    importer = Curry::ImportPullRequestCommitAuthors.new(pull_request)
    importer.import_commit_authors

    user = create(:user)
    account = create(
      :account,
      user: user,
      username: 'brettchalupa',
      provider: 'github'
    )
    create(:icla_signature, user: user)

    importer.import_commit_authors

    brett = pull_request.commit_authors.with_login('brettchalupa').first!

    expect(brett).to be_authorized_to_contribute
  end

  context 'when commit authors become uninvolved with a Pull Request' do
    it 'removes the uninvolved commit authors from the Pull Request' do
      repository = create(:repository, owner: 'gofullstack', name: 'paprika')
      pull_request = create(:pull_request, repository: repository)
      pull_request.commit_authors.create!(login: 'squashed_away')
      pull_request.commit_authors.create!(email: 'squashed_away@example.com')
      pull_request.commit_authors.create!(email: 'squashed_away_too@example.com')

      importer = Curry::ImportPullRequestCommitAuthors.new(pull_request)

      expect do
        importer.import_commit_authors
      end.to change(pull_request.reload.unknown_commit_authors, :count).by(-1)
    end

    it 'does not remove the commit author record altogether' do
      repository = create(:repository, owner: 'gofullstack', name: 'paprika')
      pull_request = create(:pull_request, repository: repository)
      pull_request.commit_authors.create!(login: 'squashed_away')
      pull_request.commit_authors.create!(email: 'squashed_away@example.com')
      pull_request.commit_authors.create!(email: 'squashed_away_too@example.com')

      importer = Curry::ImportPullRequestCommitAuthors.new(pull_request)

      expect do
        importer.import_commit_authors
      end.to change(Curry::CommitAuthor, :count).by(2)
    end
  end

end
