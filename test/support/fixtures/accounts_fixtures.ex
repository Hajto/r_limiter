defmodule Limiter.AccountsFixtures do
  import Limiter.Helpers

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      hawku_token: create_token()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Limiter.Accounts.create_user()
    user
  end
end
