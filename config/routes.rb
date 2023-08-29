Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "home#index"

  # Defines the authentication routes.
  get "login", to: "authentication#login"
  patch "login", to: "authentication#totp_handler"
  post "login", to: "authentication#login_post"
  delete "logout", to: "authentication#logout"
  get "forgot_password", to: "authentication#forgot_password_enter_email"
  post "forgot_password", to: "authentication#forgot_password_enter_email_post"
  get "forgot_password/:token", to: "authentication#forgot_password_remainder"
  post "forgot_password/:token", to: "authentication#forgot_password_remainder_post"
  get "register", to: "authentication#register_enter_email"
  post "register", to: "authentication#register_enter_email_post"
  get "register/:token", to: "authentication#register_remainder"
  post "register/:token", to: "authentication#register_remainder_post"
  get "email/update/:token", to: "authentication#email_change_token_click"

  # Defines the Turbo components (used when a component is too slow to load with the rest of the page or encapsulates a lot of logic).
  get 'components/user_list', to: 'turbo_components#user_list'
  get 'components/skeet_media_frame/:frame_id/:url', to: 'turbo_components/media_frame#skeet_media_frame', constraints: { frame_id: /[^\/]+/, url: /[^\/]+/ }
  patch 'components/skeet_action', to: 'turbo_components/skeet_action#skeet_action'
  get 'components/home_feed/:did', to: 'turbo_components#home_feed', constraints: { did: /[^\/]+/ }
  get 'components/user_settings', to: 'turbo_components/settings#user_settings'
  patch 'components/user_settings', to: 'turbo_components/settings#user_settings_patch'
  get 'components/bluesky_user_settings/:did', to: 'turbo_components/settings#bluesky_user_settings', constraints: { did: /[^\/]+/ }
  patch 'components/bluesky_user_settings/:did', to: 'turbo_components/settings#bluesky_user_settings_patch', constraints: { did: /[^\/]+/ }
  delete 'components/bluesky_user_settings/:did', to: 'turbo_components/settings#bluesky_user_settings_delete', constraints: { did: /[^\/]+/ }

  # Defines a VERY slim API for the AJAX calls.
  get "ajax/notification_count/:did", to: "ajax#notification_count"
  get "ajax/home_feed", to: "ajax#home_feed"

  # Defines the homepage routes.
  get "home", to: "home#home"
  get "home/new", to: "home#new_user"
  post "home/new", to: "home#new_user_post"
  get "home/:did", to: "home#home_did"
  get "home/:did/settings", to: "home#settings_skeleton"
  get "accept_invite/:code", to: "home#accept_invite"

  # Handle post viewing.
  get "post/:identifier/:post_id", to: "post#view", constraints: { identifier: /[^\/]+/, post_id: /[^\/]+/ }
end
