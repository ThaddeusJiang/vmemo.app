defmodule VmemoWeb.HomePageLive do
  require Logger
  use VmemoWeb, :live_view

  alias Vmemo.PhotoService.TsPhoto

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id

    col = 1

    socket =
      socket
      |> assign(:photos, load_photos("", 1, user_id))
      |> assign(:page, 1)
      |> assign(q: "")
      |> assign(:window_width, 0)
      |> assign(:col, col)

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

  @impl true
  def handle_event("window_resize", %{"width" => width}, socket) do
    col =
      cond do
        width >= 768 -> 4
        width >= 640 -> 3
        true -> 2
      end

    {:noreply,
     socket
     |> assign(:window_width, width)
     |> assign(:col, col)}
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

  def split_list(list, n) do
    list
    |> Enum.with_index()
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

      <div id="photos" phx-hook="Resize">
        <div class={
          "grid gap-2"
          <> case @col do
            2 -> " grid-cols-2"
            3 -> " grid-cols-3"
            4 -> " grid-cols-4"
            _ -> " hidden"
          end
        }>
          <div :for={photos <- @photos |> split_list(@col)} class="space-y-2">
            <.link
              :for={photo <- photos}
              navigate={~p"/photos/#{photo.id}"}
              class="link link-hover block"
            >
              <img src={photo.url} alt={photo.note} class="w-full h-auto object-cover rounded shadow" />
            </.link>
          </div>
        </div>
      </div>

      <div phx-hook="InfiniteScroll" id="infinite-scroll"></div>
    </div>
    """
  end
end
