defmodule VmemoWeb.HomePageLive do
  use VmemoWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :photos, [])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    hello HomePage
    """
  end
end
