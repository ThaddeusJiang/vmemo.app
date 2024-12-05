defmodule VmemoWeb.PageController do
  use VmemoWeb, :controller

  def landing(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :landing, layout: false)
  end
end
