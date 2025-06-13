defmodule TealMultiplayer.Game do
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field :game_id, :string
    field :status, :string, default: "waiting"
    field :created_at, :utc_datetime
    field :updated_at, :utc_datetime

    has_many :players, TealMultiplayer.Player
  end

  def changeset(game, attrs) do
    game
    |> cast(attrs, [:game_id, :status])
    |> validate_required([:game_id])
    |> unique_constraint(:game_id)
    |> put_timestamps()
  end

  defp put_timestamps(changeset) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    
    changeset
    |> put_change(:created_at, now)
    |> put_change(:updated_at, now)
  end
end