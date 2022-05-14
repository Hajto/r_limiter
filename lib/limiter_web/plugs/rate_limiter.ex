defmodule RateLimiter do
  import Plug.Conn

  def init(default), do: default

  def call(conn, _default) do
    IO.inspect(conn, label: :conn)
    conn
    # |> configure_session(renew: true)
    # |> clear_session()
    |> put_session(:hawku_token, "AAA")
    |> IO.inspect(label: :pipe)


    # c = Cachex.put(:rate_limiter)
    # IO.inspect(conn, label: :conn)
    # assign(conn, :locale, default)
    # conn
  end
end
