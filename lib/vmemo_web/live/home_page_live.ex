defmodule VmemoWeb.HomePageLive do
  require Logger
  use VmemoWeb, :live_view

  alias Vmemo.PhotoService.TsPhoto

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id
    photos = TsPhoto.hybird_search_photos("", user_id: user_id)

    socket =
      socket
      |> assign(photos: photos)
      |> assign(q: "")
      |> assign(:window_width, 0)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    user_id = socket.assigns.current_user.id
    q = Map.get(params, "q", "")
    photos = TsPhoto.hybird_search_photos(q, user_id: user_id)

    {:noreply, assign(socket, photos: photos, q: q)}
  end

  def split_list(list, n) do
    Enum.with_index(list)
    |> Enum.group_by(fn {_elem, index} -> rem(index, n) end)
    |> Enum.map(fn {_key, group} -> Enum.map(group, &elem(&1, 0)) end)
  end

  @impl true
  def handle_event("window_resize", %{"width" => width}, socket) do
    {:noreply, assign(socket, window_width: width)}
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
        <%= if @window_width > 0 do %>
          <%= cond do %>
            <% @window_width >= 768 -> %>
              <div class="grid grid-cols-4 gap-4">
                <%= for photos  <- @photos |> split_list(4)  do %>
                  <div class="space-y-4">
                    <%= for photo  <- photos do %>
                      <.link navigate={~p"/photos/#{photo["id"]}"} class="link link-hover block">
                        <img
                          src={photo["url"]}
                          alt={photo["caption"]}
                          class="w-full h-auto object-cover rounded shadow"
                        />
                      </.link>
                    <% end %>
                  </div>
                <% end %>
              </div>
            <% @window_width >= 640 -> %>
              <div class="grid grid-cols-3 gap-4">
                <%= for photos  <- @photos |> split_list(3)  do %>
                  <div class="space-y-4">
                    <%= for photo  <- photos do %>
                      <.link navigate={~p"/photos/#{photo["id"]}"} class="link link-hover block">
                        <img
                          src={photo["url"]}
                          alt={photo["caption"]}
                          class="w-full h-auto object-cover rounded shadow"
                        />
                      </.link>
                    <% end %>
                  </div>
                <% end %>
              </div>
            <% true -> %>
              <div class="grid grid-cols-2 gap-4">
                <%= for photos  <- @photos |> split_list(2)  do %>
                  <div class="space-y-4">
                    <%= for photo  <- photos do %>
                      <.link navigate={~p"/photos/#{photo["id"]}"} class="link link-hover block">
                        <img
                          src={photo["url"]}
                          alt={photo["caption"]}
                          class="w-full h-auto object-cover rounded shadow"
                        />
                      </.link>
                    <% end %>
                  </div>
                <% end %>
              </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end
end
