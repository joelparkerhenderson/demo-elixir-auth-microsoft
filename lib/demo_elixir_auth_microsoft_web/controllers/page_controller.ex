defmodule DemoElixirAuthMicrosoftWeb.PageController do
  use DemoElixirAuthMicrosoftWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

end
