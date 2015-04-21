ManageIQ::Application.routes.draw do
  VERSION_PATTERN = /latest|([0-9_\-\.]+)/ unless defined?(VERSION_PATTERN)

  if Rails.env.development?
    mount MailPreview => 'mail_view'
  end

  namespace :api, defaults: { format: :json }  do
    namespace :v1 do
      get 'metrics' => 'metrics#show'
      get 'health' => 'health#show'
      get 'users/:user' => 'users#show', as: :user
      get 'tools/:tool' => 'tools#show', as: :tool
      get 'tools' => 'tools#index', as: :tools
      get 'tools-search' => 'tools#search', as: :tools_search
    end
  end

  # get 'cookbooks-directory' => 'cookbooks#directory'
  get 'universe' => 'api/v1/universe#index', defaults: { format: :json }
  get 'status' => 'api/v1/health#show', defaults: { format: :json }
  get 'unsubscribe/:token' => 'email_preferences#unsubscribe', as: :unsubscribe

  put 'cookbooks/:id/transfer_ownership' => 'transfer_ownership#transfer', as: :transfer_ownership
  get 'ownership_transfer/:token/accept' => 'transfer_ownership#accept', as: :accept_transfer
  get 'ownership_transfer/:token/decline' => 'transfer_ownership#decline', as: :decline_transfer

  resources :collaborators, only: [:index, :new, :create, :destroy] do
    member do
      put :transfer
    end
  end

  resources :users, only: [:show] do
    member do
      get :tools, constraints: proc { ROLLOUT.active?(:tools) }

      put :make_admin
      delete :revoke_admin
      # get :followed_cookbook_activity, format: :atom
    end

    resources :accounts, only: [:destroy]
  end

  resources :tools, constraints: proc { ROLLOUT.active?(:tools) } do
    member do
      post :adoption
    end
  end
  get 'tools-directory' => 'tools#directory', constraints: proc { ROLLOUT.active?(:tools) }

  resource :profile, controller: 'profile', only: [:update, :edit] do
    post :update_install_preference, format: :json

    collection do
      patch :change_password
      get :link_github, path: 'link-github'
    end
  end

  # resources :invitations, constraints: proc { ROLLOUT.active?(:cla) && ROLLOUT.active?(:github) }, only: [:show] do
  #   member do
  #     get :accept
  #     get :decline
  #   end
  # end

  # resources :organizations, constraints: proc { ROLLOUT.active?(:cla) && ROLLOUT.active?(:github) }, only: [:show, :destroy] do
  #   member do
  #     put :combine

  #     get :requests_to_join, constraints: proc { ROLLOUT.active?(:join_ccla) && ROLLOUT.active?(:github) }
  #   end

  #   resources :contributors, only: [:update, :destroy], controller: :contributors, constraints: proc { ROLLOUT.active?(:cla) && ROLLOUT.active?(:github) }

  #   resources :invitations, only: [:index, :create, :update], constraints: proc { ROLLOUT.active?(:cla) && ROLLOUT.active?(:github) },
  #                           controller: :organization_invitations do

  #     member do
  #       patch :resend
  #       delete :revoke
  #     end
  #   end
  # end

  # get 'become-a-contributor' => 'contributors#become_a_contributor', constraints: proc { ROLLOUT.active?(:cla) && ROLLOUT.active?(:github) }
  # get 'contributors' => 'contributors#index', constraints: proc { ROLLOUT.active?(:cla) }

  get 'chat' => 'irc_logs#index'
  get 'chat/:channel' => 'irc_logs#show'
  get 'chat/:channel/:date' => 'irc_logs#show'

  match 'auth/github/callback' => 'sessions#create', as: :auth_session_callback, via: [:get, :post]

  get 'auth/failure' => 'sessions#failure', as: :auth_failure
  get 'login'   => redirect('/sign-in'), as: nil
  get 'signin'  => redirect('/sign-in'), as: nil
  get 'sign-in' => 'sessions#new', as: :sign_in
  get 'sign-up' => 'sessions#new', as: :sign_up

  delete 'logout'   => redirect('/sign-out'), as: nil
  delete 'signout'  => redirect('/sign-out'), as: nil
  delete 'sign-out' => 'sessions#destroy', as: :sign_out

  # when linking an oauth account
  match 'auth/:provider/callback' => 'accounts#create', as: :auth_callback, via: [:get, :post]

  # this is what a logged in user sees after login
  get 'dashboard' => 'pages#dashboard'
  get 'robots.:format' => 'pages#robots'
  root 'pages#welcome'
end
