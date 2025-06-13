defmodule TealMultiplayerWeb.PageController do
  use TealMultiplayerWeb, :controller
  alias TealMultiplayer.Games

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def create_game(conn, _params) do
    case Games.create_game() do
      {:ok, game} ->
        session_id = get_session(conn, :session_id)
        
        case Games.join_game(game.game_id, "Player", session_id) do
          {:ok, _player} ->
            redirect(conn, to: ~p"/waiting-room/#{game.game_id}")
          {:error, _reason} ->
            conn
            |> put_flash(:error, "Failed to join game")
            |> redirect(to: ~p"/")
        end
      
      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to create game")
        |> redirect(to: ~p"/")
    end
  end

  def join_game(conn, %{"game_id" => game_id}) do
    session_id = get_session(conn, :session_id)
    
    case Games.join_game(game_id, "Player", session_id) do
      {:ok, _player} ->
        redirect(conn, to: ~p"/waiting-room/#{game_id}")
      {:error, :game_not_found} ->
        conn
        |> put_flash(:error, "Game not found")
        |> redirect(to: ~p"/")
      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to join game")
        |> redirect(to: ~p"/")
    end
  end
end
