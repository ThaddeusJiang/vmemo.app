defmodule VmemoWeb.PhotoIdLive do
  require Logger
  use VmemoWeb, :live_view

  alias Vmemo.PhotoService.TsPhoto

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    user_id = socket.assigns.current_user.id
    {:ok, photo} = TsPhoto.get_photo(id)
    photos = TsPhoto.list_similar_photos(photo["id"], user_id: user_id)

    socket =
      socket
      |> assign(photo: photo)
      |> assign(photos: photos)
      |> assign_new(:note_form, fn ->
        to_form(%{
          "note" => photo["note"]
        })
      end)

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

        <.form class="w-full h-full flex flex-col gap-4 " for={@note_form} phx-submit="update_note">
          <textarea
            id={@note_form[:note].id}
            name={@note_form[:note].name}
            class="w-full h-24 p-2 text-lg border border-gray-300 rounded shadow"
          ><%= Phoenix.HTML.Form.normalize_value("textarea", @note_form[:note].value) %></textarea>
          <button
            type="submit"
            class="w-full p-2 text-lg font-semibold text-white bg-blue-500 rounded shadow"
          >
            Update note
          </button>
        </.form>
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

  @impl true
  def handle_event("update_note", %{"note" => note}, socket) do
    {:ok, _} = TsPhoto.update_note(socket.assigns.photo["id"], note)

    {:noreply, socket}
  end
end
