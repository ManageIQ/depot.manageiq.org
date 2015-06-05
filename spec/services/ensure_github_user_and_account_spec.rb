require "spec_helper"

describe EnsureGithubUserAndAccount do
  let(:github_user) do
    {
      login: "cvincent",
      name: "Chris Vincent",
      email: "example@example.com"
    }
  end

  subject { EnsureGithubUserAndAccount.new(github_user) }

  it "creates a new account and user" do
    user, account = subject.process!

    expect(user.persisted?).to be(true)
    expect(user.first_name).to eq("Chris")
    expect(user.last_name).to eq("Vincent")
    expect(user.email).to eq("example@example.com")

    expect(account.persisted?).to be(true)
    expect(account.username).to eq("cvincent")
    expect(account.provider).to eq("github")
  end

  it "does not create a new account if one exists" do
    Account.new(username: "cvincent", provider: "github").save(validate: false)
    expect { subject.process! }.not_to change { Account.count }
  end
end
