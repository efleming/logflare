defmodule LogflareWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use LogflareWeb, :controller
      use LogflareWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: LogflareWeb

      import LogflareWeb.Gettext
      import Plug.Conn
      import Phoenix.LiveView.Controller

      alias LogflareWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      alias Logflare.JSON

      use Phoenix.View,
        root: "lib/logflare_web/templates",
        namespace: LogflareWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Use all HTML functionality (forms, tags, etc)
      unquote(view_helpers())
    end
  end

  defp view_helpers do
    quote do
      use Phoenix.HTML

      import Phoenix.LiveView.Helpers
      import LogflareWeb.LiveHelpers
      import PhoenixLiveReact, only: [live_react_component: 2, live_react_component: 3]

      import Phoenix.View

      import LogflareWeb.ErrorHelpers
      import LogflareWeb.Gettext
      alias LogflareWeb.Router.Helpers, as: Routes
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {LogflareWeb.LayoutView, "live.html"}

      import PhoenixLiveReact, only: [live_react_component: 2, live_react_component: 3]

      unquote(view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel, log_join: false, log_handle_in: false
      import LogflareWeb.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
