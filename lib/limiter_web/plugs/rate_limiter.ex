defmodule RateLimiter do
  import Plug.Conn
  import Phoenix.Controller
  alias Plug.Conn.Status
  alias LimiterWeb.Router.Helpers, as: Routes

  alias Limiter.Accounts
  @default_req_count 2
  # in seconds
  @default_timeframe 1
  @default_name :rate_limiter_cache
  @default_token :hawku
  @defaults [name: @default_name, timeframe: @default_timeframe, req_count: @default_req_count, token: @default_token]

  def init(opts \\ @defaults) do
    opts
    |> cache_name()
    |> Cachex.start()
  end

  def call(conn, opts \\ @defaults) do
    conn
    |> validate_user()
    |> update_cache(opts)
  end
  # headers hardcoded to user ID - assume that anyone w/ a hawku token is valid
  defp validate_user(conn) do
    case get_token(conn) do
      nil ->
        conn
        |> put_flash(:error, "unauthorized")
        |> redirect(to: Routes.page_path(conn, :index))
        |> halt()

      _token -> conn
    end
  end

  defp update_cache(%{halted: true} = conn, _opts), do: conn

  defp update_cache(conn, opts) do
    conn
    |> lookup_cache(opts)
    |> verify_key_existence(opts)
    |> check_rate(opts)
  end

  def get_token(conn) do
    conn
    |> get_session(:user_id)
    |> Accounts.get_user!()
    |> Map.get(:hawku_token)
  end

  defp cache_name(opts), do: Keyword.get(opts, :name, @default_name)
  defp req_count(opts), do: Keyword.get(opts, :req_count, @default_req_count)
  defp timeframe(opts), do: Keyword.get(opts, :timeframe, @default_timeframe)

  defp lookup_cache(conn, opts), do: {conn, cache_name(opts), get_session(conn, :user_id)}

  # initialize key if it doesn't already exist
  # the value is a map with two properties: the count of connections
  # and the timestamp for the most recent request
  defp verify_key_existence({conn, cache_name, key}, opts) do
    case Cachex.exists?(cache_name, key) do
      {_, true} -> nil
      {_, false} ->
        Cachex.put(cache_name, key, %{
          counter: req_count(opts),
          last_req_recvd_at: DateTime.utc_now()
        })
    end
    {conn, cache_name, key}
  end

  defp time_diff(last_req_timestamp, timeframe) do
    Enum.min([DateTime.utc_now(), DateTime.add(last_req_timestamp, timeframe, :second)], Date)
  end

  # based on https://medium.com/smyte/rate-limiter-df3408325846
  defp check_rate({conn, cache_name, key}, opts)  do
    {:ok, %{counter: counter, last_req_recvd_at: lrra}} = Cachex.get(cache_name, key)

    refill_count = floor(DateTime.diff(DateTime.utc_now(), lrra) / timeframe(opts))
    new_counter = min(req_count(opts), counter + refill_count)
    time_diff = time_diff(lrra, timeframe(opts))

    case new_counter do
      0 ->
        conn
        |> put_flash(:error, "too many requests")
        |> put_status(Status.code(:too_many_requests))
        |> put_resp_header("retry-after", Date.to_string(time_diff))
        |> halt()
      _ ->
        Cachex.update(cache_name, key, %{
          counter: new_counter - 1,
          last_req_recvd_at: time_diff
        })

        conn
        |> put_resp_header("x-rate-limit", req_count(opts) |> Integer.to_string())
        |> put_resp_header("x-rate-limit-remaining", (new_counter - 1) |> Integer.to_string())
        |> put_flash(:info, "success")
    end
  end
end
