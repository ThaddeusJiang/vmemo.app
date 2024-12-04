defmodule VmemoWeb.PhotoIdLive do
  use VmemoWeb, :live_view

  alias Vmemo.PhotoService.TsPhoto

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    user_id = socket.assigns.current_user.id
    {:ok, photo} = TsPhoto.get_photo(id)
    photos = TsPhoto.list_similar_photos(photo["id"], user_id: user_id)

    socket = socket |> assign(photo: photo, photos: photos)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container flex-col space-y-10">
      <div class="grid grid-cols-1 gap-4 h-2/3 ">
        <div class="space-y-4">
          <img
            src={@photo["url"]}
            alt={@photo["note"]}
            class="w-full h-auto object-cover rounded shadow"
          />
        </div>
      </div>

      <div class="container">
        <h2 class="text-lg font-semibold text-gray-900 dark:text-gray-50">
          Similar photos
        </h2>
        <div class="grid grid-cols-3 gap-4">
          <%= for photo <- @photos do %>
            <div class="space-y-4">
              <.link navigate={~p"/photos/#{photo["id"]}"}>
                <img
                  src={photo["url"]}
                  alt={photo["note"]}
                  class="w-full h-auto object-cover rounded shadow"
                />
              </.link>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
