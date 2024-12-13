defmodule VmemoWeb.HomePageLive do
  require Logger
  use VmemoWeb, :live_view

  alias Vmemo.PhotoService.TsPhoto

  alias VmemoWeb.Live.Components.WaterfallLc

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id

    socket =
      socket
      |> assign(:photos, load_photos("", 1, user_id))
      |> assign(:page, 1)
      |> assign(q: "")

    {:ok, socket}
  end

  @impl true
  def handle_event("load_more", _, socket) do
    user_id = socket.assigns.current_user.id
    q = socket.assigns.q

    page = socket.assigns.page + 1
    more_photos = load_photos(q, page, user_id)

    {:noreply,
     socket
     |> update(:photos, &(&1 ++ more_photos))
     |> assign(:page, page)}
  end

  defp load_photos(q, page, user_id) do
    TsPhoto.hybird_search_photos(q, user_id: user_id, page: page)
  end

  @impl true
  def handle_params(params, _uri, socket) do
    user_id = socket.assigns.current_user.id

    q = Map.get(params, "q", "")
    page = 1

    photos = load_photos(q, page, user_id)

    {:noreply,
     socket
     |> assign(:photos, photos)
     |> assign(:page, page)
     |> assign(:q, q)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-4 w-full max-w-screen-lg mx-auto">
      <%!-- search box --%>
      <form action="/home" method="get">
        <input
          type="search"
          name="q"
          class="border border-zinc-200 rounded-lg px-2 py-1 text-zinc-900 w-full"
          placeholder="Search"
          value={@q}
        />
        <%!-- search when typing --%>
      </form>

      <.live_component id="waterfall-photos" module={WaterfallLc} items={@photos} />

      <div phx-hook="InfiniteScroll" id="infinite-scroll"></div>
    </div>
    """
  end
end
