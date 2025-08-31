# Demo Elixir Auth Microsoft

Demonstration of:

* Elixir Phoenix web application

* The Hex package elixir-auth-microsoft

* Authentication via Microsoft Entra Azure Active Directory

<https://github.com/dwyl/elixir-auth-microsoft>

## Run

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies

* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## How to create this demo yourself

Run:

```sh
curl https://new.phoenixframework.org/demo_elixir_auth_microsoft | sh
mv demo_elixir_auth_microsoft demo-elixir-auth-microsoft && cd $_
```

## 1. Add the hex package to deps

Follow the instructions:<br>
<https://github.com/dwyl/elixir-auth-microsoft>

Edit `mix.deps` section `deps`. 

Append `{:elixir_auth_microsoft, "~> 1.1.0"}`.

Run:

```sh
mix deps.get
```

## 2. Create an App Registration in Entry Azure Active Directory

Follow the instructions:<br>
<https://github.com/dwyl/elixir-auth-microsoft/blob/main/azure_app_registration_guide.md>

When we created this demo, Microsoft used this URL:<br>
<https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade>

## 3. Export Environment / Application Variables

TODO: what are good ways to have Phoenix load the environment variables?

Run:

```sh
export MICROSOFT_SCOPES_LIST="User.Read openid profile"
export MICROSOFT_CLIENT_ID=85228de4-cf4f-4249-ae05-247365
export MICROSOFT_CLIENT_SECRET=rDq8Q~.uc-237FryAt-lGu7G1sQkKR
export MICROSOFT_CALLBACK_PATH="/auth/microsoft/sign-in-callback"
export MICROSOFT_POST_LOGOUT_REDIRECT_URI="http://localhost:4000/auth/microsoft/sign-out-callback"
```

## 4. Add a "Sign in with Microsoft" Button to your App

Compare this controller:

* <https://github.com/dwyl/elixir-auth-microsoft/blob/main/demo/lib/app_web/controllers/page_controller.ex>

Compare this template:

* <https://github.com/dwyl/elixir-auth-microsoft/blob/main/demo/lib/app_web/templates/page/index.html.heex>

By default, the controller, view module, and templates are collocated together in
the same controller directory, such as:

* foo_controller.ex defines FooController which has `bar` function.

* foo_html.ex defines FooHTML which has `embed_templates "foo_html/*"`

* foo_html is a directory that contains `bar.heex`.

### 4.1. Create controller

Create file:

* <lib/demo_elixir_auth_microsoft/controllers/auth_microsoft_controller.ex>

TODO: Find out what the docs mean by "random uuid". In the meantime, we generate
a random UUID such as "86fe2e1e-8697-11f0-93ef-471b95dd0c36" and use it where
the docs say to use it.

```elixir
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

  export MICROSOFT_CALLBACK_PATH="/auth/microsoft/sign-in-callback"
  """
  def sign_in(conn, _params) do
    state = "random_state_uid"
    oauth_url = ElixirAuthMicrosoft.generate_oauth_url_authorize(conn, state)
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

  %{
    scope: "openid profile",
    access_token: "…",
      expires_in: 3599,
      ext_expires_in: 3599,
      id_token: "…",
      token_type: "Bearer"
  }

  `get_user_profile/1` fetches the signed-in Microsoft User info according to
  the token that is passed by calling get_token/1.
  """
  def sign_in_callback(conn, %{"code" => code, "state" => state}) do

    # Perform state change here (to prevent CSRF)
    if state !== "random_state_uid" do
      # error handling
    end

    {:ok, token} = ElixirAuthMicrosoft.get_token(code, conn)
    {:ok, profile} = ElixirAuthMicrosoft.get_user_profile(token.access_token)

    conn
    |> put_session(:token, token)
    |> render(:sign_in_callback, %{token: token, profile: profile})
  end

  @doc """
  `sign_out/2` show the "Sign Out" link for Microsoft Auth API.

  `generate_oauth_url_logout/0` creates a logout URL. This should the URL the
  person is redirected to when they want to logout. To define the redirect URL
  (the URL that the user will be redirected to after successful logout from
  Microsoft ), you need to set the env var MICROSOFT_POST_LOGOUT_REDIRECT_URI or
  set the property :post_logout_redirect_uri in your config files.

  Example:

  export MICROSOFT_POST_LOGOUT_REDIRECT_URI="http://localhost:4000/auth/microsoft/sign-out-callback"
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
```

### 4.2. Create view module

Create file `lib/demo_elixir_auth_microsoft/controllers/auth_microsoft_html.ex`:

```elixir
defmodule DemoElixirAuthMicrosoftWeb.AuthMicrosoftHTML do
  @moduledoc """
  This module contains pages rendered by AuthMicrosoftController.

  See the `auth_microsoft_html` directory for all templates available.
  """
  use DemoElixirAuthMicrosoftWeb, :html

  embed_templates "auth_microsoft_html/*"
end
```

### 4.3. Create sign-in.heex

Create file `lib/demo_elixir_auth_microsoft/controllers/auth_microsoft_html/sign-in.heex`:

```html
<a href={@oauth_url}>
  <img src="https://learn.microsoft.com/en-us/azure/active-directory/develop/media/howto-add-branding-in-azure-ad-apps/ms-symbollockup_signin_light.png" alt="Sign in with Microsoft" />
</a>
```

### 4.4. Create sign-in-callback.heex

Create file `lib/demo_elixir_auth_microsoft/controllers/auth_microsoft_html/sign-in-callback.heex`:

```html
<h1>Sign in callback</h1>
<section><%= @token %></section>
<section><%= @profile %></section>
```

### 4.5. Create sign-out.heex

Create file `lib/demo_elixir_auth_microsoft/controllers/auth_microsoft_html/sign-out.heex`:

```html
<a href={@oauth_url}>
    Sign out
</a>
```

### 4.6. Create sign-out-callback.heex

Create file `lib/demo_elixir_auth_microsoft/controllers/auth_microsoft_html/sign-out-callback.heex`:

```html
<h1>Sign out callback</h1>
```

## 5. Use the Built-in Functions to Authenticate People

Compare:

* <https://github.com/dwyl/elixir-auth-microsoft/blob/main/demo/lib/app_web/controllers/microsoft_auth_controller.ex>

TODO: what to do for error handling?

## 6. Add the `/auth/microsoft/callback` to `router.ex`

Edit `lib/demo_elixir_auth_microsoft_web/router.ex`.

From this:

```elixir
scope "/", DemoElixirAuthMicrosoftWeb do
  pipe_through :browser

  get "/", PageController, :home
end
```

Into this:

```elixir
scope "/", DemoElixirAuthMicrosoftWeb do
  pipe_through :browser

  get "/", PageController, :home
  get "/auth/microsoft/sign-in", AuthMicrosoftController, :sign_in
  get "/auth/microsoft/sign-in-callback", AuthMicrosoftController, :sign_in_callback
  get "/auth/microsoft/sign-out", AuthMicrosoftController, :sign_out
  get "/auth/microsoft/sign-out-callback", AuthMicrosoftController, :sign_out_callback
end
```

Create file `lib/DemoElixirAuthMicrosoftWeb/controllers/microsoft_auth_html.ex`:

```elixir
defmodule DemoElixirAuthMicrosoftWeb.MicrosoftAuthHTML do
  @moduledoc """
  This module contains pages rendered by MicrosoftoAuthController.

  See the `microsoft_auth_html` directory for all templates available.
  """
  use DemoElixirAuthMicrosoftWeb, :html

  embed_templates "microsoft_auth_html/*"
end
```

Create file `lib/DemoElixirAuthMicrosoftWeb/controllers/microsoft_auth_html/success.html.heex`:

```heex
<h1>Microsoft Auth Success</h1>
<p>Your login is successful.</p>
```
