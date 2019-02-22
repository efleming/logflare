defmodule LogflareWeb.Plugs.SetUser do
  import Plug.Conn

  alias Logflare.Repo
  alias Logflare.User

  def init(_params) do
  end

  def call(conn, _params) do
    headers = Enum.into(conn.req_headers, %{})
    user_id = get_session(conn, :user_id)
    api_key = headers["x-api-key"]

    cond do
      user = user_id && Repo.get(User, user_id) ->
        assign(conn, :user, user)

      user = api_key && Repo.get_by(User, api_key: api_key) ->
        IO.inspect(assign(conn, :user, user))

      true ->
        assign(conn, :user, nil)
    end
  end
end
