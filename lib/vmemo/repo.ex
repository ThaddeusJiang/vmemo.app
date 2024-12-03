defmodule Vmemo.Repo do
  use Ecto.Repo,
    otp_app: :vmemo,
    adapter: Ecto.Adapters.Postgres
end
