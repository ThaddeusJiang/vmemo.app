defmodule VmemoWeb.PhotoIdLive do
  require Logger
  use Gettext, backend: VmemoWeb.Gettext

  use VmemoWeb, :live_view

  alias Vmemo.PhotoService.TsPhoto

  alias VmemoWeb.LiveComponents.Waterfall

  @impl true
  def mount(%{"id" => id, "action" => action}, _session, socket) do
    user_id = socket.assigns.current_user.id
    {:ok, %{photo: photo, notes: notes}} = TsPhoto.get(id, :notes)

    if photo == nil do
      {:ok,
       socket
       |> assign(photo: nil)
       |> assign(notes: [])}
    else
      photos = TsPhoto.list_similar_photos(photo.id, user_id: user_id)

      socket =
        socket
        |> assign(photo: photo)
        |> assign(notes: notes)
        |> assign(show_expanded: false)
        |> assign(photos: photos)
        |> assign_new(:form, fn ->
          to_form(%{
            "note" => photo.note,
            "_gen_description" => photo._gen_description
          })
        end)
        |> assign(:action, action)

      {:ok, socket}
    end
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    user_id = socket.assigns.current_user.id
    {:ok, %{photo: photo, notes: notes}} = TsPhoto.get(id, :notes)

    if photo == nil do
      {:ok, socket |> assign(photo: nil) |> assign(notes: [])}
    else
      photos = TsPhoto.list_similar_photos(photo.id, user_id: user_id)

      socket =
        socket
        |> assign(photo: photo)
        |> assign(notes: notes)
        |> assign(show_expanded: false)
        |> assign(photos: photos)
        |> assign_new(:form, fn ->
          to_form(%{
            "note" => photo.note,
            "_gen_description" => photo._gen_description
          })
        end)
        |> assign(:action, "edit")

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
  def handle_event("save", %{"note" => note, "_gen_description" => gen_description}, socket) do
    {:ok, _} =
      TsPhoto.update(socket.assigns.photo.id, %{note: note, _gen_description: gen_description})

    {:noreply,
     socket
     |> put_flash(:info, "Saved")}
  end

  @impl true
  def handle_event("gen_description", _, socket) do
    case TsPhoto.gen_description(socket.assigns.photo.id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Description generated")}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to generate description: #{reason}")}
    end
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
    <div class="p-4 sm:py-6 lg:px-8">
      <%= if @photo == nil do %>
        <.not_found />
      <% else %>
        <div class=" flex flex-col space-y-10 w-full mx-auto max-w-screen-lg">
          <div class=" gap-4 space-y-4 sm:grid sm:grid-cols-2 sm:space-y-0 max-h-[60%] ">
            <div class="space-y-4 flex justify-center relative">
              <figure class="w-auto h-auto group relative">
                <%!-- <figcaption class="text-lg font-semibold text-gray-900">
                  <%= @photo.note %>
                </figcaption> --%>

                <%= if @photo._gen_description do %>
                  <.button
                    variant="outline"
                    class=" absolute top-2 left-2 btn-circle text-green-500"
                    aria-label={gettext("AI trained")}
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      width="24"
                      height="24"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      class="lucide lucide-brain-circuit w-4 h-4 inline "
                    >
                      <path d="M12 5a3 3 0 1 0-5.997.125 4 4 0 0 0-2.526 5.77 4 4 0 0 0 .556 6.588A4 4 0 1 0 12 18Z" /><path d="M9 13a4.5 4.5 0 0 0 3-4" /><path d="M6.003 5.125A3 3 0 0 0 6.401 6.5" /><path d="M3.477 10.896a4 4 0 0 1 .585-.396" /><path d="M6 18a4 4 0 0 1-1.967-.516" /><path d="M12 13h4" /><path d="M12 18h6a2 2 0 0 1 2 2v1" /><path d="M12 8h8" /><path d="M16 8V5a2 2 0 0 1 2-2" /><circle
                        cx="16"
                        cy="13"
                        r=".5"
                      /><circle cx="18" cy="3" r=".5" /><circle cx="20" cy="21" r=".5" /><circle
                        cx="20"
                        cy="8"
                        r=".5"
                      />
                    </svg>
                  </.button>
                <% else %>
                  <.button
                    variant="outline"
                    class=" absolute top-2 left-2 btn-circle btn-icon"
                    aria-label={gettext("AI trained")}
                    phx-click="gen_description"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      width="24"
                      height="24"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      class="lucide lucide-brain-circuit w-4 h-4 inline "
                    >
                      <path d="M12 5a3 3 0 1 0-5.997.125 4 4 0 0 0-2.526 5.77 4 4 0 0 0 .556 6.588A4 4 0 1 0 12 18Z" /><path d="M9 13a4.5 4.5 0 0 0 3-4" /><path d="M6.003 5.125A3 3 0 0 0 6.401 6.5" /><path d="M3.477 10.896a4 4 0 0 1 .585-.396" /><path d="M6 18a4 4 0 0 1-1.967-.516" /><path d="M12 13h4" /><path d="M12 18h6a2 2 0 0 1 2 2v1" /><path d="M12 8h8" /><path d="M16 8V5a2 2 0 0 1 2-2" /><circle
                        cx="16"
                        cy="13"
                        r=".5"
                      /><circle cx="18" cy="3" r=".5" /><circle cx="20" cy="21" r=".5" /><circle
                        cx="20"
                        cy="8"
                        r=".5"
                      />
                    </svg>
                  </.button>
                <% end %>

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

                <.link
                  href={@photo.url}
                  class=" absolute bottom-2 right-2 btn btn-circle hidden group-hover:flex sm:group-hover:hidden"
                  aria-label={gettext("expand")}
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                    class="size-4"
                  >
                    <path d="M6.41421 5H10V3H3V10H5V6.41421L9.29289 10.7071L10.7071 9.29289L6.41421 5ZM21 14H19V17.5858L14.7071 13.2929L13.2929 14.7071L17.5858 19H14V21H21V14Z">
                    </path>
                  </svg>
                </.link>

                <.button
                  variant="outline"
                  phx-click="show_expanded"
                  aria-label={gettext("expand")}
                  class=" absolute bottom-2 right-2 btn-circle hidden group-hover:hidden sm:group-hover:block"
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

            <.form
              class={[
                " w-full flex flex-col gap-4 ",
                if @action == "edit" do
                  "block"
                else
                  "hidden"
                end
              ]}
              for={@form}
              phx-submit="save"
            >
              <.textarea_field
                id={@form[:note].id}
                name={@form[:note].name}
                value={@form[:note].value}
                label="Note"
              />

              <.textarea_field
                id={@form[:_gen_description].id}
                name={@form[:_gen_description].name}
                value={@form[:_gen_description].value}
                label="Description"
              />

              <.button phx-disable-with="Saving">Save</.button>
            </.form>
          </div>

          <div class="grid gap-4 grid-cols-4">
            <div class="space-y-2 col-span-4 sm:col-span-3 lg:col-span-2">
              <h2 class="text-lg font-semibold">
                Similar photos({length(@photos)})
              </h2>

              <.live_component id="similar-photos" module={Waterfall} items={@photos}>
                <:card :let={photo}>
                  <.link navigate={~p"/photos/#{photo.id}"} class="link link-hover block">
                    <.img src={photo.url} alt={photo.note} />
                  </.link>
                </:card>
              </.live_component>
            </div>

            <div class="space-y-2 col-span-4 sm:col-span-1 lg:col-span-2">
              <h2 class="text-lg font-semibold ">
                References({length(@notes)})
              </h2>

              <div class="space-y-2">
                <.link
                  :for={note <- @notes}
                  navigate={~p"/notes/#{note.id}"}
                  class="link link-hover block"
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="1.5"
                    stroke="currentColor"
                    class="size-4 inline-block"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M13.19 8.688a4.5 4.5 0 0 1 1.242 7.244l-4.5 4.5a4.5 4.5 0 0 1-6.364-6.364l1.757-1.757m13.35-.622 1.757-1.757a4.5 4.5 0 0 0-6.364-6.364l-4.5 4.5a4.5 4.5 0 0 0 1.242 7.244"
                    />
                  </svg>

                  <span>{note.text}</span>
                </.link>
              </div>
            </div>
          </div>
        </div>

        <.modal :if={@show_expanded} id="expanded_photo" show on_cancel={JS.push("hide_extened")}>
          <.img src={@photo.url} alt={@photo.note} />
        </.modal>
      <% end %>
    </div>
    """
  end
end
