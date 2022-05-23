defmodule Limiter.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :hawku_token, :string

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:hawku_token])
    # |> validate_required([:hawku_token])
  end
end
