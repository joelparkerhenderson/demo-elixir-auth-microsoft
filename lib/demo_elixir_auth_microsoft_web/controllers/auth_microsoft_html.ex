defmodule DemoElixirAuthMicrosoftWeb.AuthMicrosoftHTML do
  @moduledoc """
  This module contains pages rendered by AuthMicrosoftSignInController.

  See the `auth_microsoft_html` directory for all templates available.
  """
  use DemoElixirAuthMicrosoftWeb, :html

  embed_templates "auth_microsoft_html/*"
end
