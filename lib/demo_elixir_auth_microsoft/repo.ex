defmodule DemoElixirAuthMicrosoft.Repo do
  use Ecto.Repo,
    otp_app: :demo_elixir_auth_microsoft,
    adapter: Ecto.Adapters.Postgres
end
