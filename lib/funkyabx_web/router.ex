defmodule FunkyABXWeb.Router do
  use FunkyABXWeb, :router

  import FunkyABXWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {FunkyABXWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user

    plug RemoteIp,
      clients: ~w[10.0.2.2/32]

    plug FunkyABXWeb.Plugs.Ip
  end

  pipeline :api do
    #    plug RemoteIp,
    #      clients: ~w[10.0.2.2/32]
    #
    #    plug FunkyABXWeb.Plugs.Ip

    plug :accepts, ["json"]
    plug FunkyABXWeb.Plugs.Auth
  end

  pipeline :test do
    plug FunkyABXWeb.Plugs.TestTaken
  end

  pipeline :test_password do
    plug FunkyABXWeb.Plugs.TestPassword
  end

  pipeline :form do
    plug FunkyABXWeb.Plugs.TestParams
  end

  scope "/", FunkyABXWeb do
    pipe_through [:browser, :test, :test_password]

    live "/test/:slug", TestLive, as: :test_public
    live "/results/:slug", TestResultsLive, as: :test_results_public
  end

  scope "/", FunkyABXWeb do
    pipe_through [:browser, :test]

    live "/results/:slug/:key", TestResultsLive, as: :test_results_private
  end

  scope "/", FunkyABXWeb do
    pipe_through :api

    post "/test_api", TestController, :test_api_new
  end

  scope "/", FunkyABXWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/about", PageController, :about
    get "/gallery", PageController, :gallery
    get "/contact", PageController, :contact
    post "/contact", PageController, :contact_submit
    get "/auth/:slug", TestController, :password
    post "/auth/:slug", TestController, :password_verify
    live "/info", FlashLive, as: :info

    live "/local_test/results/:data/:choices", TestResultsLive, as: :local_test_results
    live "/local_test/:data", TestLive, as: :local_test
  end

  scope "/", FunkyABXWeb do
    pipe_through [:browser, :form]

    live "/edit/:slug/:key", TestFormLive, as: :test_edit_private
    live "/test", TestFormLive, as: :test_new
    live "/local_test/edit/:data", LocalTestFormLive, as: :local_test_edit
    live "/local_test", LocalTestFormLive, as: :local_test_new
  end

  # Other scopes may use custom stacks.
  # scope "/api", FunkyABXWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: FunkyABXWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/uploads" do
      pipe_through :browser

      get "/:part1/:part2", FunkyABXWeb.DevController, :redirect_file
    end

    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", FunkyABXWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", FunkyABXWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    delete "/users/settings", UserSettingsController, :delete
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email

    get "/users/settings/api_key", UserSettingsApiKeyController, :index
    post "/users/settings/api_key", UserSettingsApiKeyController, :generate
    get "/users/settings/api_key/delete/:key", UserSettingsApiKeyController, :delete

    live "/edit/:slug", TestFormLive, as: :test_edit
    live "/user/tests", TestListLive, as: :test_list
  end

  scope "/", FunkyABXWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
  end

  scope "/api/swagger" do
    forward "/", PhoenixSwagger.Plug.SwaggerUI, otp_app: :funkyabx, swagger_file: "swagger.json"
  end

  def swagger_info do
    %{
      info: %{
        version: "1.0",
        title: "FunkyABX"
      }
    }
  end
end
