defmodule FunkyABXWeb.Router do
  use FunkyABXWeb, :router

  import FunkyABXWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session

    plug Cldr.Plug.PutLocale,
      apps: [:cldr, :gettext],
      from: [:accept_language, :cookie, :session, :query],
      gettext: FunkyABXWeb.Gettext,
      cldr: FunkyABX.Cldr

    plug :fetch_live_flash
    plug :put_root_layout, html: {FunkyABXWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user

    plug RemoteIp,
      clients: ~w[10.0.2.2/32]

    plug FunkyABXWeb.Plugs.Ip
    plug FunkyABXWeb.Plugs.Embed
  end

  pipeline :test_password do
    plug FunkyABXWeb.Plugs.TestPassword
  end

  pipeline :form do
    plug FunkyABXWeb.Plugs.TestParams
  end

  scope "/", FunkyABXWeb do
    pipe_through [:browser, :test_password]

    live_session :current_user_test_one,
      on_mount: [{FunkyABXWeb.UserAuth, :mount_current_scope}] do
      live "/test/:slug", TestLive, as: :test_public
      live "/results/:slug", TestResultsLive, as: :test_results_public
    end
  end

  scope "/", FunkyABXWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/about", PageController, :about
    get "/faq", PageController, :faq
    get "/donate", PageController, :donate

    get "/contact", PageController, :contact
    post "/contact", PageController, :contact_submit

    get "/auth/:slug", TestController, :password
    post "/auth/:slug", TestController, :password_verify

    get "/img/results/:filename", TestController, :image

    live_session :current_user_test_two,
      on_mount: [{FunkyABXWeb.UserAuth, :mount_current_scope}] do
      live "/info", FlashLive, as: :info
      live "/gallery", GalleryLive, :gallery

      live "/results/:slug/:key", TestResultsLive, as: :test_results_private
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", FunkyABXWeb do
  #   pipe_through :api
  # end

  scope "/", FunkyABXWeb do
    pipe_through [:browser, :form]

    live_session :current_user_form,
      on_mount: [{FunkyABXWeb.UserAuth, :mount_current_scope}] do
      live "/edit/:slug/:key", TestFormLive, as: :test_edit_private
      live "/test", TestFormLive, as: :test_new

      # local test has to be grouped together otherwise LV generates another page load and audio files are lost
      live "/local_test/edit/:data", LocalTestFormLive, as: :local_test_edit
      live "/local_test", LocalTestFormLive, as: :local_test_new
      live "/local_test/results/:data/:choices", TestResultsLive
      live "/local_test/results/:data/:choices/:tracks_order", TestResultsLive
      live "/local_test/:data", TestLive, as: :local_test
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:funkyabx, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: FunkyABXWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  if Mix.env() == :dev do
    scope "/uploads" do
      pipe_through :browser

      get "/:part1/:part2", FunkyABXWeb.DevController, :redirect_file
    end
  end

  ## Authentication routes

  scope "/", FunkyABXWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{FunkyABXWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit

      live "/edit/:slug", TestFormLive, as: :test_edit
      live "/user/tests", TestListLive, as: :test_list
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", FunkyABXWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{FunkyABXWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
    get "/users/log-out", UserSessionController, :delete
  end
end
