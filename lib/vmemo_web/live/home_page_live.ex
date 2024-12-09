defmodule VmemoWeb.HomePageLive do
  require Logger
  use VmemoWeb, :live_view

  alias Vmemo.PhotoService.TsPhoto

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id

    socket =
      socket
      |> stream(:photos, load_photos("", 1, user_id))
      |> assign(:page, 1)
      |> assign(q: "")
      |> assign(:window_width, 0)

    {:ok, socket}
  end

  @impl true
  def handle_event("load-more", %{"page" => page}, socket) do
    user_id = socket.assigns.current_user.id
    q = socket.assigns.q

    socket =
      socket
      |> stream(:photos, load_photos(q, page, user_id))
      |> assign(page: page + 1)

    {:noreply, socket}
  end

  @impl true
  def handle_event("window_resize", %{"width" => width}, socket) do
    {:noreply, assign(socket, window_width: width)}
  end

  defp load_photos(q, page, user_id) do
    TsPhoto.hybird_search_photos(q, user_id: user_id, page: page)
    |> Enum.map(&TsPhoto.parse/1)
  end

  @impl true
  def handle_params(params, _uri, socket) do
    user_id = socket.assigns.current_user.id
    q = Map.get(params, "q", "")
    photos = TsPhoto.hybird_search_photos(q, user_id: user_id)

    {:noreply, assign(socket, photos: photos, q: q)}
  end

  def split_list(list, n) do
    list
    |> Enum.group_by(fn {_elem, index} -> rem(index, n) end)
    |> Enum.map(fn {_key, group} -> Enum.map(group, &elem(&1, 0)) end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container flex flex-col gap-8">
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

      <div id="photos" phx-update="stream" class="space-y-4">
        <div id="phtos-empty" class="only:block hidden">
          <div>No photos found</div>
        </div>
        <div :for={{dom_id, photo} <- @streams.photos} id={dom_id} class="space-y-2">
          <.link navigate={~p"/photos/#{photo.id}"} class="link link-hover block">
            <img src={photo.url} alt={photo.note} class="w-full h-auto object-cover rounded shadow" />
          </.link>
        </div>
      </div>

      <%!-- TODO: don't need data-page , don't need passs params to client --%>
      <div id="loader" phx-hook="InfiniteScroll" data-page={@page} id="infinite-scroll-marker"></div>
    </div>
    """
  end
end
