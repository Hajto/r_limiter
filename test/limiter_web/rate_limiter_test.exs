defmodule LimiterWeb.RateLimiterTest do
  use LimiterWeb.ConnCase
  import Limiter.AccountsFixtures
  alias RateLimiter

  describe "rate limiting plug" do
    @describetag :this

    setup %{conn: conn} do
      %{hawku_token: token} = user = user_fixture()

      conn =
        conn
        |> init_test_session(%{})
        |> put_req_header("hawku", token)

      %{conn: conn, user: user}
    end

    @custom [name: :group_a, req_count: 5]

    test "things", %{conn: conn, user: user} do

      RateLimiter.init()
      RateLimiter.init(@custom)
      # RateLimiter.init([req_count: 10])
      conn =
        conn
        |> fetch_flash()
        |> RateLimiter.call()
        |> RateLimiter.call(@custom)

      assert get_flash(conn, :info) == "success"

      conn =
        conn
        |> fetch_flash()
        |> RateLimiter.call()
        # # |> RateLimiter.call(@custom)

      {:ok, %{counter: counter}} = Cachex.get(:rate_limiter_cache, user.id)
      assert get_flash(conn, :error) == "too many requests"
      assert conn.status == 429
      assert counter == 0

      user2 = user_fixture(%{hawku: nil})

      conn = put_req_header(conn, "hawku", "")

      conn
      |> IO.inspect(label: :pipe)
      |> fetch_flash()
      |> RateLimiter.call()

      assert get_flash(conn, :error) == "unauthorized"
      # conn
      # |> put_req_header("hawku", token)
      # |> RateLimiter.call()


      # {:ok, %{counter: counter_custom}} = Cachex.get(:group_a, user.id)

      # assert counter == 9

      # {:ok, %{counter: counter_2}} = Cachex.get(:rate_limiter_cache, user_2.id)

    end
  end
end
