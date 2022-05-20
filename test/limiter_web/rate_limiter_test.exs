defmodule LimiterWeb.RateLimiterTest do
  use LimiterWeb.ConnCase
  import Limiter.AccountsFixtures
  alias RateLimiter

  describe "rate limiting plug" do
    @describetag :this

    setup %{conn: conn} do
      %{hawku_token: token} = user_fixture()

      conn =
        conn
        |> init_test_session(%{})
        |> put_req_header("hawku", token)

      %{conn: conn}
    end

    @defaults_a [name: :group_a, req_count: 5]

    test "things", %{conn: conn} do
      # IO.inspect(conn, label: :conn)

      RateLimiter.init([])
      # RateLimiter.init(@defaults_a)
      RateLimiter.init(@defaults_a)
      # RateLimiter.init([req_count: 10])
      conn =
        conn
        |> fetch_flash()
        |> RateLimiter.call(@defaults_a)
        # |> IO.inspect(label: :pipe)

      IO.inspect(conn.assigns, label: :conn)
      # IO.inspect(conn, label: :conn)
      # c = Cachex.get(:cats, :q)
      # IO.inspect(c, label: :c)
    end

  end
end
