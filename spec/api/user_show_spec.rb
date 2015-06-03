require 'spec_helper'

describe 'GET /api/v1/users/:user' do
  context 'when the user exists' do
    let!(:user) do
      create(
        :user,
        first_name: 'Fanny',
        last_name: 'McNanny',
        company: 'Fanny Pack',
        twitter_username: 'fanny',
        irc_nickname: 'fanny',
        jira_username: 'fanny',
        create_chef_account: false
      )
    end

    let!(:user_signature) do
      {
        "username" => "fanny",
        "name" => "Fanny McNanny",
        "company" => "Fanny Pack",
        "github" => ["fanny"],
        "twitter" => "fanny",
        "irc" => "fanny",
        "jira" => "fanny"
      }
    end

    before do
      create(
        :account,
        provider: 'github',
        username: 'fanny',
        user: user
      )
    end

    it 'returns a 200' do
      get '/api/v1/users/fanny'
      expect(response.status.to_i).to eql(200)
    end

    it 'returns the user' do
      get '/api/v1/users/fanny'
      expect(signature(json_body)).to eql(user_signature)
    end
  end

  context 'when the user does not exist' do
    it 'returns a 404' do
      get '/api/v1/users/notauser'

      expect(response.status.to_i).to eql(404)
    end

    it 'returns a 404 message' do
      get '/api/v1/users/notauser'

      expect(json_body).to eql(error_404)
    end
  end
end
