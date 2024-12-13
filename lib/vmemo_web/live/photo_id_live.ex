defmodule VmemoWeb.PhotoIdLive do
  require Logger

  use VmemoWeb, :live_view

  alias Vmemo.PhotoService.TsPhoto

  alias VmemoWeb.Live.Components.WaterfallLc

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    user_id = socket.assigns.current_user.id
    photo = TsPhoto.get_photo(id)
    # TODO: handle 404
    photos = TsPhoto.list_similar_photos(photo.id, user_id: user_id)

    socket =
      socket
      |> assign(photo: photo)
      |> assign(photos: photos)
      |> assign_new(:note_form, fn ->
        to_form(%{
          "note" => photo.note
        })
      end)

    {:ok, socket}
  end

  @impl true
  def handle_event("delete_photo", %{"id" => id}, socket) do
    {:ok, _} = TsPhoto.delete_photo(id)

    {:noreply,
     socket
     |> put_flash(:info, "Deleted")
     |> push_navigate(to: ~p"/photos")}
  end

  @impl true
  def handle_event("update_note", %{"note" => note}, socket) do
    {:ok, _} = TsPhoto.update_note(socket.assigns.photo.id, note)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class=" flex flex-col space-y-10 mx-auto sm:max-w-screen-md">
      <div class=" gap-4 space-y-4 sm:grid sm:grid-cols-2 sm:space-y-0 max-h-[60%] ">
        <div class="space-y-4 flex justify-center relative">
          <figure class="w-auto h-auto max-h-[60%] group">
            <%!-- <figcaption class="text-lg font-semibold text-gray-900 dark:text-gray-50">
              <%= @photo.note %>
            </figcaption> --%>

            <.img src={@photo.url} alt={@photo.note} />
            <.button
              variant="danger"
              phx-click="delete_photo"
              phx-value-id={@photo.id}
              class="absolute top-2 right-2 p-2 btn-circle hidden group-hover:block"
            >
              &times;
            </.button>
          </figure>
        </div>

        <.form class=" w-full flex flex-col gap-4 " for={@note_form} phx-submit="update_note">
          <textarea
            id={@note_form[:note].id}
            name={@note_form[:note].name}
            class="p-2 text-lg border border-gray-300 rounded shadow"
          ><%= Phoenix.HTML.Form.normalize_value("textarea", @note_form[:note].value) %></textarea>
          <button type="submit" class="btn btn-accent w-full" phx-disable-with="Updating">
            Update
          </button>
        </.form>
      </div>

      <div class=" space-y-2">
        <h2 class="text-lg font-semibold text-gray-900 dark:text-gray-50">
          Similar photos
        </h2>

        <.live_component id="similar-photos" module={WaterfallLc} items={@photos} />
      </div>
    </div>
    """
  end
end
