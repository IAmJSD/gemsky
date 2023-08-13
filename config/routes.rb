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
  get "email/update/:token", to: "authentication#email_update_token_click"
end
