defmodule TealMultiplayer.Games do
  import Ecto.Query, warn: false
  alias TealMultiplayer.Repo
  alias TealMultiplayer.{Game, Player}

  def create_game do
    game_id = generate_game_id()
    
    %Game{}
    |> Game.changeset(%{game_id: game_id})
    |> Repo.insert()
  end

  def get_game_by_game_id(game_id) do
    Repo.get_by(Game, game_id: game_id)
  end

  def get_game_with_players(game_id) do
    case get_game_by_game_id(game_id) do
      nil -> nil
      game -> Repo.preload(game, :players)
    end
  end

  def join_game(game_id, player_name, session_id) do
    case get_game_by_game_id(game_id) do
      nil -> {:error, :game_not_found}
      game ->
        case %Player{}
             |> Player.changeset(%{
               name: player_name,
               session_id: session_id,
               game_id: game.id
             })
             |> Repo.insert() do
          {:ok, player} = result ->
            # Broadcast that a new player joined
            Phoenix.PubSub.broadcast(TealMultiplayer.PubSub, "game:#{game_id}", 
              {:player_joined, player})
            result
          error -> error
        end
    end
  end

  def update_player_name(session_id, game_db_id, new_name) do
    case Repo.get_by(Player, session_id: session_id, game_id: game_db_id) do
      nil -> {:error, :player_not_found}
      player ->
        player
        |> Player.changeset(%{name: new_name})
        |> Repo.update()
    end
  end

  def get_player_by_session(session_id, game_db_id) do
    Repo.get_by(Player, session_id: session_id, game_id: game_db_id)
  end

  def start_game(game_id) do
    case get_game_by_game_id(game_id) do
      nil -> {:error, :game_not_found}
      game ->
        game
        |> Game.changeset(%{status: "in_progress"})
        |> Repo.update()
    end
  end

  defp generate_game_id do
    :crypto.strong_rand_bytes(4)
    |> Base.encode16(case: :upper)
  end
end