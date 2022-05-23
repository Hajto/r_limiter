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

    setup %{conn: conn} do
      %{conn: conn, user: user_fixture(), invalid_user: user_fixture(%{hawku_token: nil})}
    end

    @custom [name: :group_a, req_count: 5]

    test "rate limits authorized users", %{conn: conn, user: user} do

      conn = conn
      |> init_test_session(%{user_id: user.id})
      |> put_req_header("hawku", user.hawku_token)

      RateLimiter.init()
      conn =
        conn
        |> fetch_flash()
        |> RateLimiter.call()

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

      assert get_flash(conn, :info) == "success"
      assert get_counter(:rate_limiter_cache, user.id) > 0
    end

    test "does not apply to unauthorized users", %{conn: conn, invalid_user: user} do
      conn = init_test_session(conn, %{user_id: user.id})
      RateLimiter.init(@custom)

      conn =
        conn
        # |> delete_req_header("hawku")
        |> init_test_session(id: "unauth")
        |> put_session(:user_id, user.id)
        |> fetch_flash()
        |> RateLimiter.call(@custom)

        assert get_flash(conn, :error) == "unauthorized"
        {:ok, val} = Cachex.exists?(:group_a, user.id)
        refute val
        # assert get_counter(:group_a, user.id) == 5
    end
  end
end
