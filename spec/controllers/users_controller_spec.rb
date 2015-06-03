require 'spec_helper'

describe UsersController do
  let(:user) { create(:user) }

  describe 'GET #show' do
    it 'assigns a user' do
      get :show, id: user.username

      expect(assigns[:user]).to eql(user)
    end

    it 'assigns extensions' do
      get :show, id: user.username

      expect(assigns[:extensions]).to_not be_nil
    end

    it 'assigns a specific context of extensions given the tab parameter' do
      followed_extension = create(:extension_follower, user: user).extension

      get :show, id: user.username, tab: 'follows'

      expect(assigns[:extensions]).to include(followed_extension)
    end

    it '404s when when a user somehow has a Chef account but does not exist' do
      username = user.username

      User.where(id: user.id).delete_all

      get :show, id: user.username, user_tab_string: 'activity'

      expect(response).to render_template('exceptions/404.html.erb')
    end
  end

  describe 'GET #followed_extension_activity' do
    it 'assigns a user' do
      get :followed_extension_activity, id: user.username

      expect(assigns[:user]).to eql(user)
    end

    it "assigns a user's followed extension activity" do
      get :followed_extension_activity, id: user.username

      expect(assigns[:followed_extension_activity]).to_not be_nil
    end
  end

  describe 'PUT #make_admin' do
    let(:user) { create(:user) }

    context 'the current user is an admin' do
      before { sign_in(create(:admin)) }

      it 'adds the admin role to a user' do
        put :make_admin, id: user
        user.reload
        expect(user.roles).to include('admin')
      end

      it 'redirects back to a user' do
        put :make_admin, id: user
        expect(response).to redirect_to(assigns[:user])
      end
    end

    context 'the current user is not an admin' do
      before { sign_in(create(:user)) }

      it 'renders 404' do
        put :make_admin, id: user
        expect(response.status.to_i).to eql(404)
      end
    end
  end

  describe 'DELETE #revoke_admin' do
    let(:user) { create(:admin) }

    context 'the current user is an admin' do
      before { sign_in(create(:admin)) }

      it 'removes the admin role to a user' do
        delete :revoke_admin, id: user
        user.reload
        expect(user.roles).to_not include('admin')
      end

      it 'redirects back to a user' do
        delete :revoke_admin, id: user
        expect(response).to redirect_to(assigns[:user])
      end
    end

    context 'the current user is not an admin' do
      before { sign_in(create(:user)) }

      it 'renders 404' do
        delete :revoke_admin, id: user
        expect(response.status.to_i).to eql(404)
      end
    end
  end
end
