defmodule Limiter.Helpers do
  @alphabet Enum.to_list(?a..?z)

  def create_token(num \\ 8) when is_number(num) do
    1..num
    |> Enum.map(fn(_) -> Enum.random(@alphabet) end)
    |> List.to_string
  end
end
