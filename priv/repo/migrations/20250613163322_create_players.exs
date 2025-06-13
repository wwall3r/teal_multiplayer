defmodule TealMultiplayer.Repo.Migrations.CreatePlayers do
  use Ecto.Migration

  def change do
    create table(:players) do
      add :name, :string, null: false
      add :session_id, :string, null: false
      add :game_id, references(:games, on_delete: :delete_all), null: false
      add :joined_at, :utc_datetime, null: false
    end

    create index(:players, [:game_id])
    create index(:players, [:session_id])
  end
end
