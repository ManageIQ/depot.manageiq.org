require 'spec_helper'

describe 'api/v1/users/show' do
  let!(:user) do
    create(
      :user,
      first_name: 'Fanny',
      last_name: 'McNanny',
      company: 'FannyInternational',
      twitter_username: 'fannyfannyfanny',
      irc_nickname: 'fannyfunnyfanny',
      jira_username: 'funnyfannyfunny'
    )
  end

  before do
    create(
      :account,
      provider: 'github',
      username: 'fanny',
      user: user
    )

    assign(:user, user)
    assign(:github_usernames, user.username)

    render
  end

  it "displays the user's chef username" do
    username = json_body['username']
    expect(username).to eql(user.username)
  end

  it "displays the user's name" do
    name = json_body['name']
    expect(name).to eql(user.name)
  end

  it "displays the user's company" do
    company = json_body['company']
    expect(company).to eql(user.company)
  end

  it "displays the user's github accounts" do
    github = json_body['github']
    expect(github).to eql(['fanny'])
  end

  it "displays the user's twitter handle" do
    twitter = json_body['twitter']
    expect(twitter).to eql(user.twitter_username)
  end

  it "displays the user's irc handle" do
    irc = json_body['irc']
    expect(irc).to eql(user.irc_nickname)
  end

  it "displays the user's jira username" do
    jira = json_body['jira']
    expect(jira).to eql(user.jira_username)
  end
end
