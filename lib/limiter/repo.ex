defmodule Limiter.Repo do
  use Ecto.Repo,
    otp_app: :limiter,
    adapter: Ecto.Adapters.Postgres
end
