defmodule RateLimiter do
  import Plug.Conn
  import Phoenix.Controller
  alias LimiterWeb.Router.Helpers, as: Routes

  alias Limiter.Accounts

  @default_req_count 10
  @default_timeframe 1000
  @default_name :rate_limiter_cache
  @default_token :hawku
  @defaults [name: @default_name, timeframe: @default_timeframe, req_count: @default_req_count, token: @default_token]

  defp get_cache_name(opts), do: Keyword.get(opts, :name, @default_name)
  defp get_token(opts), do: Keyword.get(opts, :token, @default_token)
  defp get_string_token(opts), do: opts |> get_token() |> Atom.to_string()

  # use user ID for the cache key
  defp cache_key_from_token(conn, opts) do
    conn.assigns[get_token(opts)]
    |> Accounts.get_user_by_token()
    |> Map.get(:id)
  end

  defp update_cache(conn, opts) do
    key = cache_key_from_token(conn, opts)
    name = get_cache_name(opts)
    IO.inspect Cachex.incr(name, key)
    # if Cachex.get(name, key) + 1 < Keyword.get(opts, :req_count, @default_req_count) do
    #   c = Cachex.get(name, key)
    #   IO.inspect(c)
    # end
    conn

    # Plug.Conn.Status.code(429)
    # conn
    # get_cache_name(opts)
    # |> Cachex.incr(cache_key_from_token(token))
  end

  def init(opts \\ @defaults) do
    opts
    |> get_cache_name()
    |> Cachex.start([limit: Keyword.get(opts, :req_count, @default_req_count)])

    opts
  end


  def call(conn, opts) do
    conn
    |> validate_user(opts)
    |> update_cache(opts)
  end

  # headers hardcoded to user ID - assume that anyone w/ a hawku token is valid
  defp validate_user(conn, opts) do
    case get_req_header(conn, get_string_token(opts)) do
      [token] -> assign(conn, get_token(opts), token)
      _ ->
        conn
        |> put_flash(:error, "unauthorized")
        |> redirect(to: Routes.page_path(conn, :index))
        |> halt()
    end
  end
end
