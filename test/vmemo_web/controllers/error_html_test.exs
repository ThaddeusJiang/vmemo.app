defmodule VmemoWeb.ErrorHTMLTest do
  use VmemoWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template

  test "renders 404.html", %{conn: conn} do
    conn = get(conn, "/wrong/path")

    assert html_response(conn, 404) =~ "Page not found"
  end

  test "renders 500.html" do
    assert render_to_string(VmemoWeb.ErrorHTML, "500", "html", []) == "Internal Server Error"
  end
end
