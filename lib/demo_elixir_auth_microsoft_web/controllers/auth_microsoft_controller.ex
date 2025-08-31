defmodule DemoElixirAuthMicrosoftWeb.AuthMicrosoftController do
  use DemoElixirAuthMicrosoftWeb, :controller

  @spec sign_in(Plug.Conn.t(), any()) :: Plug.Conn.t()
  @doc """
  `index/2` show the "Sign In" button for Microsoft Auth API.q

  `generate_oauth_url_authorize/1` creates an OAuth2 URL with client_id,
  redirect_uri and scopes (be sure to create the app registration in Azure
  Portal AD). The redirect_uri will be the URL Microsoft will redirect after
  successful sign-in. This is the URL that you should be used in a "Login with
  Microsoft"-type button.

  `generate_oauth_url_authorize/2` is the same as generate_oauth_url_authorize/1
  but with a state parameter. This state parameter should be compared with the
  one that is sent as query param in the redirect URI after the sign-in is
  successful.

  You can set your callback path with an env var MICROSOFT_CALLBACK_PATH or set
  the property `:callback_path` in your config files.

  Example:

  ```sh
  export MICROSOFT_CALLBACK_PATH="/auth/microsoft/sign-in-callback"
  ```

  Regarding the state parameter (the random_state_uid you mentioned), it isn't
  so much related to CORS but it's actually a CSRF (Cross-Site Request Forgery)
  protection mechanism. Here's how it works:

  When starting OAuth flow*the app generates a random, unpredictable value and
  includes it in the authorization URL. Microsoft stores it: Microsoft's OAuth
  server remembers this value during the auth process. On callback, Microsoft
  sends the same state value back to the app. The app verifies that   the returned
  state matches what you originally sent. The "random_state_uid" in our demo is
  indeed a simplified example. In production, it should be a cryptographically
  secure random value that is stored in session and verified on callback to
  prevent CSRF attacks.
  """
  def sign_in(conn, _params) do
    csrf_protection_random_state = :crypto.strong_rand_bytes(32) |> Base.url_encode64()
    conn = put_session(conn, :csrf_protection_random_state, csrf_protection_random_state)

    oauth_url = ElixirAuthMicrosoft.generate_oauth_url_authorize(conn, csrf_protection_random_state)
    render(conn, :sign_in, [oauth_url: oauth_url])
  end

  @doc """
  `sign_in_callback/2` handle the callback from Microsoft Auth API sign in
  redirect.

  `get_token/2` fetches the ID token using the authorization code that was
  previously obtained. Env variables are used to encode information while
  fetching the ID token from Microsoft, including the registered client ID that
  was created in Azure Portal AD.

  The token should be something like:

  ```elixir
  %{
    scope: "openid profile",
    access_token: "…",
      expires_in: 3599,
      ext_expires_in: 3599,
      id_token: "…",
      token_type: "Bearer"
  }
  ```

  `get_user_profile/1` fetches the signed-in Microsoft User info according to
  the token that is passed by calling get_token/1.
  """
  def sign_in_callback(conn, %{"code" => code, "state" => state}) do

    csrf_protection_random_state = get_session(conn, :csrf_protection_random_state)

    if state != csrf_protection_random_state do
      conn
      |> put_flash(:error, "Invalid state parameter")
      |> redirect(to: "/auth/microsoft/sign-in")
    else
      conn = delete_session(conn, :csrf_protection_random_state)
      {:ok, token} = ElixirAuthMicrosoft.get_token(code, conn)
      {:ok, profile} = ElixirAuthMicrosoft.get_user_profile(token.access_token)
      conn
      |> put_session(:token, token)
      |> render(:sign_in_callback, %{token: token, profile: profile})
    end
  end

  @doc """
  `sign_out/2` show the "Sign Out" link for Microsoft Auth API.

  `generate_oauth_url_logout/0` creates a logout URL. This should the URL the
  person is redirected to when they want to logout. To define the redirect URL
  (the URL that the user will be redirected to after successful logout from
  Microsoft ), you need to set the env var MICROSOFT_POST_LOGOUT_REDIRECT_URI or
  set the property :post_logout_redirect_uri in your config files.

  Example:

  ```sh
  export MICROSOFT_POST_LOGOUT_REDIRECT_URI="http://localhost:4000/auth/microsoft/sign-out-callback"
  ```
  """
  def sign_out(conn, _params) do
    oauth_url = ElixirAuthMicrosoft.generate_oauth_url_logout()
    render(conn, :sign_out, [oauth_url: oauth_url])
  end

  @doc """
  `sign_out_callback/2` handle the callback from Microsoft Auth API redirect after user logs out.
  """
  def sign_out_callback(conn, _params) do

    # Clear the token from the user session
    conn = conn |> delete_session(:token)

    conn
    |> redirect(to: "/auth/microsoft/sign-in")
  end

end
