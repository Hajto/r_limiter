defmodule LimiterWeb.RateLimiterTest do
  use LimiterWeb.ConnCase
  import Limiter.AccountsFixtures
  alias RateLimiter

  setup %{conn: conn} do
    %{hawku_token: token} = user_fixture()
    conn =
      conn
      |> init_test_session(%{hawku_token: token})

    %{conn: conn}
  end

  describe "rate limiting plug" do
    @describetag :this
    test "things", %{conn: conn} do
      # conn(:get, "/")
      conn = RateLimiter.call(conn, [])
      IO.inspect(conn, label: :conn)
    end

  end
end
