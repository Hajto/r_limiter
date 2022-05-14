defmodule Limiter.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :hawku_token, :string

      timestamps()
    end
  end
end
