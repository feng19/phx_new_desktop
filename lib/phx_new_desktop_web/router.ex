defmodule PhxNewDesktopWeb.Router do
  use PhxNewDesktopWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PhxNewDesktopWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", PhxNewDesktopWeb do
    pipe_through :browser

    live "/", GenLive
  end
end
