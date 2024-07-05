defmodule OidcTest.Repo do
  use Ecto.Repo,
    otp_app: :oidc_test,
    adapter: Ecto.Adapters.Postgres
end
