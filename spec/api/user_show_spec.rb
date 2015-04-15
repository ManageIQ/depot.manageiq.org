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
         "username"   =>"fanny",
         "name"   =>"Fanny McNanny",
         "company"   =>"Fanny Pack",
         "github"   =>   [  
            "fanny"
         ],
         "twitter"   =>"fanny",
         "irc"   =>"fanny",
         "jira"   =>"fanny",
         "tools"   =>   {  
            "owns"      =>      {  
               "berkshelf"         =>"http://www.example.com/api/v1/tools/berkshelf",
               "knife_supermarket"         =>"http://www.example.com/api/v1/tools/knife_supermarket"
            },
            "collaborates"      =>      {  
               "dull_knife"         =>"http://www.example.com/api/v1/tools/dull_knife"
            }
         }
      }
    end

    before do
      create(
        :account,
        provider: 'github',
        username: 'fanny',
        user: user
      )
      create(:tool, name: 'berkshelf', owner: user, slug: 'berkshelf')
      create(
        :tool, name: 'knife_supermarket', owner: user, slug: 'knife_supermarket'
      )

      create(
        :tool_collaborator,
        resourceable: create(:tool, name: 'dull_knife', slug: 'dull_knife'),
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
