defmodule TealMultiplayer.Player do
  use Ecto.Schema
  import Ecto.Changeset

  schema "players" do
    field :name, :string
    field :session_id, :string
    field :joined_at, :utc_datetime

    belongs_to :game, TealMultiplayer.Game
  end

  def changeset(player, attrs) do
    player
    |> cast(attrs, [:name, :session_id, :game_id])
    |> validate_required([:name, :session_id, :game_id])
    |> put_joined_at()
  end

  defp put_joined_at(changeset) do
    put_change(changeset, :joined_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end
end