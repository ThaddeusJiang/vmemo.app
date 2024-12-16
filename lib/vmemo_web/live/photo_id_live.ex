defmodule VmemoWeb.PhotoIdLive do
  require Logger
  use Gettext, backend: VmemoWeb.Gettext
  use VmemoWeb, :live_view

  alias Vmemo.PhotoService.TsPhoto

  alias VmemoWeb.Live.Components.WaterfallLc

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    user_id = socket.assigns.current_user.id
    photo = TsPhoto.get_photo(id)

    if photo == nil do
      {:ok, socket |> assign(photo: nil)}
    else
      photos = TsPhoto.list_similar_photos(photo.id, user_id: user_id)

      socket =
        socket
        |> assign(photo: photo)
        |> assign(show_expanded: false)
        |> assign(photos: photos)
        |> assign_new(:note_form, fn ->
          to_form(%{
            "note" => photo.note
          })
        end)

      {:ok, socket}
    end
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

    {:noreply,
     socket
     |> put_flash(:info, "Updated")}
  end

  @impl true
  def handle_event("show_expanded", _, socket) do
    {:noreply, socket |> assign(show_expanded: true)}
  end

  @impl true
  def handle_event("hide_extened", _, socket) do
    {:noreply, socket |> assign(show_expanded: false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @photo == nil do %>
      <.not_found />
    <% else %>
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
                data-confirm="You can't undo this action. Are you sure?"
                class="absolute top-2 right-2 btn-circle hidden group-hover:block"
                aria-label={gettext("delete")}
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  class="w-4 h-4 inline"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0"
                  />
                </svg>
              </.button>

              <.button
                variant="outline"
                phx-click="show_expanded"
                class=" absolute bottom-2 right-2 btn-circle hidden group-hover:block"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                  class="h-4 w-4 inline"
                >
                  <path d="M6.41421 5H10V3H3V10H5V6.41421L9.29289 10.7071L10.7071 9.29289L6.41421 5ZM21 14H19V17.5858L14.7071 13.2929L13.2929 14.7071L17.5858 19H14V21H21V14Z">
                  </path>
                </svg>
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

          <.live_component id="similar-photos" module={WaterfallLc} items={@photos}>
            <:card :let={photo}>
              <.link navigate={~p"/photos/#{photo.id}"} class="link link-hover block">
                <.img src={photo.url} alt={photo.note} />
              </.link>
            </:card>
          </.live_component>
        </div>
      </div>

      <.modal :if={@show_expanded} id="expanded_photo" show on_cancel={JS.push("hide_extened")}>
        <.img src={@photo.url} alt={@photo.note} />
      </.modal>
    <% end %>
    """
  end
end
