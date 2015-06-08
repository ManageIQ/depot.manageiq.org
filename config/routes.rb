ManageIQ::Application.routes.draw do
  VERSION_PATTERN = /latest|([0-9_\-\.]+)/ unless defined?(VERSION_PATTERN)

  if Rails.env.development?
    mount MailPreview => 'mail_view'
  end

  namespace :api, defaults: { format: :json }  do
    namespace :v1 do
      get 'metrics' => 'metrics#show'
      get 'health' => 'health#show'
      get 'extensions' => 'extensions#index'
      get 'search' => 'extensions#search'
      get 'extensions/:extension' => 'extensions#show', as: :extension
      get 'extensions/:extension/versions/:version' => 'extension_versions#show', as: :extension_version, constraints: { version: VERSION_PATTERN }
      get 'extensions/:extension/versions/:version/download' => 'extension_versions#download', as: :extension_version_download, constraints: { version: VERSION_PATTERN }
      delete 'extensions/:extension/versions/:version' => 'extension_uploads#destroy_version', constraints: { version: VERSION_PATTERN }
      get 'users/:user' => 'users#show', as: :user
    end
  end

  get 'extensions-directory' => 'extensions#directory'
  get 'universe' => 'api/v1/universe#index', defaults: { format: :json }
  get 'status' => 'api/v1/health#show', defaults: { format: :json }
  get 'unsubscribe/:token' => 'email_preferences#unsubscribe', as: :unsubscribe

  put 'extensions/:id/transfer_ownership' => 'transfer_ownership#transfer', as: :transfer_ownership
  get 'ownership_transfer/:token/accept' => 'transfer_ownership#accept', as: :accept_transfer
  get 'ownership_transfer/:token/decline' => 'transfer_ownership#decline', as: :decline_transfer

  resources :extensions, only: [:index, :new, :create, :show, :update] do
    member do
      get :download
      put :follow
      delete :unfollow
      put :deprecate
      delete :deprecate, action: 'undeprecate'
      put :toggle_featured
      get :deprecate_search
      post :adoption
    end

    get 'versions/:version/download' => 'extension_versions#download', as: :version_download, constraints: { version: VERSION_PATTERN }
    get 'versions/:version' => 'extension_versions#show', as: :version, constraints: { version: VERSION_PATTERN }
  end

  resources :collaborators, only: [:index, :new, :create, :destroy] do
    member do
      put :transfer
    end
  end

  resources :users, only: [:show] do
    member do
      put :make_admin
      delete :revoke_admin
      get :followed_extension_activity, format: :atom
    end

    resources :accounts, only: [:destroy]
  end

  resource :profile, controller: 'profile', only: [:update, :edit] do
    post :update_install_preference, format: :json

    collection do
      patch :change_password
      get :link_github, path: 'link-github'
    end
  end

  resources :invitations, constraints: proc { ROLLOUT.active?(:cla) && ROLLOUT.active?(:github) }, only: [:show] do
    member do
      get :accept
      get :decline
    end
  end

  resources :organizations, constraints: proc { ROLLOUT.active?(:cla) && ROLLOUT.active?(:github) }, only: [:show, :destroy] do
    member do
      put :combine

      get :requests_to_join, constraints: proc { ROLLOUT.active?(:join_ccla) && ROLLOUT.active?(:github) }
    end

    resources :contributors, only: [:update, :destroy], controller: :contributors, constraints: proc { ROLLOUT.active?(:cla) && ROLLOUT.active?(:github) }

    resources :invitations, only: [:index, :create, :update], constraints: proc { ROLLOUT.active?(:cla) && ROLLOUT.active?(:github) },
                            controller: :organization_invitations do

      member do
        patch :resend
        delete :revoke
      end
    end
  end

  get 'become-a-contributor' => 'contributors#become_a_contributor', constraints: proc { ROLLOUT.active?(:cla) && ROLLOUT.active?(:github) }
  get 'contributors' => 'contributors#index', constraints: proc { ROLLOUT.active?(:cla) }

  get 'chat' => 'irc_logs#index'
  get 'chat/:channel' => 'irc_logs#show'
  get 'chat/:channel/:date' => 'irc_logs#show'

  # when signing in or up with chef account
  # match 'auth/chef_oauth2/callback' => 'sessions#create', as: :auth_session_callback, via: [:get, :post]
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

  require "sidekiq/web"
  mount Sidekiq::Web => "/sidekiq"
end
