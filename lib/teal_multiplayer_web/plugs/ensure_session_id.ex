defmodule TealMultiplayerWeb.Plugs.EnsureSessionId do
  @moduledoc """
  Plug to ensure every request has a session_id assigned.
  If no session_id exists, generates a new one.
  """
  
  import Plug.Conn

  def init(default), do: default

  def call(conn, _default) do
    case get_session(conn, :session_id) do
      nil ->
        session_id = Base.encode16(:crypto.strong_rand_bytes(16), case: :lower)
        put_session(conn, :session_id, session_id)
      _session_id ->
        conn
    end
  end
end