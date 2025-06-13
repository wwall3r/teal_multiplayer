defmodule TealMultiplayer.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :game_id, :string, null: false
      add :status, :string, default: "waiting"
      add :created_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create unique_index(:games, [:game_id])
  end
end
