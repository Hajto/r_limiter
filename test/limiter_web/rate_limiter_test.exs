defmodule LimiterWeb.RateLimiterTest do
  use LimiterWeb.ConnCase
  import Limiter.AccountsFixtures
  alias RateLimiter

  describe "rate limiting plug" do
    @describetag :this

    defp get_counter(cache_name, user_id) do
      {:ok, %{counter: counter}} = Cachex.get(cache_name, user_id)
      counter
    end

    defp setup_session(conn, user_id, token) do
      conn
      |> init_test_session(%{user_id: user_id})
      |> put_req_header("hawku", token)
    end

    setup %{conn: conn} do
      %{hawku_token: token} = user = user_fixture()

      conn =
        conn
        |> init_test_session(%{user_id: user.id})
        |> put_req_header("hawku", token)

      %{conn: conn, user: user}
    end

    @custom [name: :group_a, req_count: 5]

    test "rate limits authorized users", %{conn: conn, user: user} do
      RateLimiter.init()
      conn =
        conn
        |> fetch_flash()
        |> RateLimiter.call()
        # |> RateLimiter.call(@custom)

      assert get_flash(conn, :info) == "success"
      assert get_counter(:rate_limiter_cache, user.id) == 1

      conn =
        conn
        |> fetch_flash()
        |> RateLimiter.call()

      assert get_flash(conn, :info) == "success"
      assert get_counter(:rate_limiter_cache, user.id) == 0

      conn =
        conn
        |> clear_flash()
        |> fetch_flash()
        |> RateLimiter.call()

      assert get_flash(conn, :error) == "too many requests"
      assert conn.status == 429
      assert get_counter(:rate_limiter_cache, user.id) == 0
      # wait for some time to pass, try again

      :timer.sleep(3000)

      conn =
        conn
        |> clear_flash()
        |> fetch_flash()
        |> RateLimiter.call()

      # assert get_flash(conn, :info) == "success"
      assert get_counter(:rate_limiter_cache, user.id) > 0
    end

    # test "does not apply to unauthorized users", %{conn: conn} do
    #   user2 = user_fixture(%{hawku_token: nil})

    #   RateLimiter.init(@custom)

    #   conn =
    #     conn
    #     |> delete_req_header("hawku")
    #     |> init_test_session(id: "unauth")
    #     |> put_session(:user_id, user2.id)
    #     |> fetch_flash()
    #     # |> recycle()
    #     |> RateLimiter.call(@custom)

    #     assert get_flash(conn, :error) == "unauthorized"
    #     assert get_counter(:group_a, user2.id) == 5
    # end
  end
end
