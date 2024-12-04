defmodule VmemoWeb.HomePageLive do
  require Logger
  use VmemoWeb, :live_view

  alias Vmemo.PhotoService.TsPhoto

  @impl true
  def mount(_params, _session, socket) do
    photos = TsPhoto.list_photos()

    Logger.debug("photos: #{inspect(photos)}")

    socket = assign(socket, photos: photos)

    {:ok, socket}
  end

  @spec split_list(any(), any()) :: list()
  def split_list(list, n) do
    Enum.with_index(list)
    |> Enum.group_by(fn {_elem, index} -> rem(index, n) end)
    |> Enum.map(fn {_key, group} -> Enum.map(group, &elem(&1, 0)) end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container">
      <div class="grid grid-cols-4 gap-4">
        <%= for photos  <- @photos |> split_list(4)  do %>
          <div class="space-y-4">
            <%= for photo  <- photos do %>
              <.link navigate={~p"/photos/#{photo["id"]}"} class="link link-hover block">
                <img
                  src={photo["url"]}
                  alt={photo["note"]}
                  class="w-full h-auto object-cover rounded shadow"
                />
              </.link>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
