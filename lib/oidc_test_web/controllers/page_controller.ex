defmodule OidcTestWeb.PageController do
  use OidcTestWeb, :controller
  import Plug.Conn

  alias Assent.{Config, Strategy.Github, Strategy.OIDC}

  def google_config do
    Application.get_env(:oidc_test, :google_config)
  end

  def github_config do
    Application.get_env(:oidc_test, :github_config)
  end

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  # http://localhost:4000/auth/github
  def github_auth(conn, _params) do
    github_config()
    |> Github.authorize_url()
    |> case do
      {:ok, %{url: url, session_params: session_params}} ->
        # Session params (used for OAuth 2.0 and OIDC strategies) will be
        # retrieved when user returns for the callback phase
        conn = put_session(conn, :session_params, session_params)

        # Redirect end-user to Github to authorize access to their account
        conn
        |> put_resp_header("location", url)
        |> send_resp(302, "")

      {:error, error} ->
        nil
        # Something went wrong generating the request authorization url
    end
  end

  def google_auth(conn, _params) do
    google_config()
    |> OIDC.authorize_url()
    |> case do
      {:ok, %{url: url, session_params: session_params}} ->
        # Session params (used for OAuth 2.0 and OIDC strategies) will be
        # retrieved when user returns for the callback phase
        conn = put_session(conn, :session_params, session_params)

        # Redirect end-user to Github to authorize access to their account
        conn
        |> put_resp_header("location", url)
        |> send_resp(302, "")

      {:error, %{response: %{body: body}} = error} ->
        IO.inspect(error)
        conn |> send_resp(500, body)
        # Something went wrong generating the request authorization url
    end
  end

  # http://localhost:4000/auth/github/callback
  def github_auth_callback(conn, _params) do
    # End-user will return to the callback URL with params attached to the
    # request. These must be passed on to the strategy. In this example we only
    # expect GET query params, but the provider could also return the user with
    # a POST request where the params is in the POST body.
    %{params: params} = fetch_query_params(conn)

    # The session params (used for OAuth 2.0 and OIDC strategies) stored in the
    # request phase will be used in the callback phase
    session_params = get_session(conn, :session_params)

    github_config()
    # Session params should be added to the config so the strategy can use them
    |> Config.put(:session_params, session_params)
    |> Github.callback(params)
    |> case do
      {:ok, %{user: user, token: token}} ->
        IO.inspect(user, label: "USER")
        IO.inspect(token, label: "Token")
        render(conn, :auth_success, user: user)

      {:error, error} ->
        render(conn, :auth_failure)
    end
  end

  def google_auth_callback(conn, _params) do
    # End-user will return to the callback URL with params attached to the
    # request. These must be passed on to the strategy. In this example we only
    # expect GET query params, but the provider could also return the user with
    # a POST request where the params is in the POST body.
    %{params: params} = fetch_query_params(conn)

    # The session params (used for OAuth 2.0 and OIDC strategies) stored in the
    # request phase will be used in the callback phase
    session_params = get_session(conn, :session_params)

    google_config()
    # Session params should be added to the config so the strategy can use them
    |> Config.put(:session_params, session_params)
    |> OIDC.callback(params)
    |> case do
      {:ok, %{user: user, token: token}} ->
        IO.inspect(user, label: "USER")
        IO.inspect(token, label: "Token")
        render(conn, :auth_success, user: user)

      {:error, error} ->
        IO.inspect(error)
        render(conn, :auth_failure)
    end
  end

end
