defmodule ShipWeb.Router do
  use ShipWeb, :router

  import ShipWeb.PlayerAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {ShipWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_player
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ShipWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", ShipWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:ship, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard",
        metrics: ShipWeb.Telemetry,
        additional_pages: [
          ecsx: ECSx.LiveDashboard.Page
        ]
    end
  end

  ## Authentication routes

  scope "/", ShipWeb do
    pipe_through [:browser, :redirect_if_player_is_authenticated]

    live_session :redirect_if_player_is_authenticated,
      on_mount: [{ShipWeb.PlayerAuth, :redirect_if_player_is_authenticated}] do
      live "/players/register", PlayerRegistrationLive, :new
      live "/players/log_in", PlayerLoginLive, :new
      live "/players/reset_password", PlayerForgotPasswordLive, :new
      live "/players/reset_password/:token", PlayerResetPasswordLive, :edit
    end

    post "/players/log_in", PlayerSessionController, :create
  end

  scope "/", ShipWeb do
    pipe_through [:browser, :require_authenticated_player]

    live_session :require_authenticated_player,
      on_mount: [{ShipWeb.PlayerAuth, :ensure_authenticated}] do
      live "/players/settings", PlayerSettingsLive, :edit
      live "/players/settings/confirm_email/:token", PlayerSettingsLive, :confirm_email
    end
  end

  scope "/", ShipWeb do
    pipe_through [:browser]

    delete "/players/log_out", PlayerSessionController, :delete

    live_session :current_player,
      on_mount: [{ShipWeb.PlayerAuth, :mount_current_player}] do
      live "/players/confirm/:token", PlayerConfirmationLive, :edit
      live "/players/confirm", PlayerConfirmationInstructionsLive, :new
    end
  end
end
