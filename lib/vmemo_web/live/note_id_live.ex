defmodule VmemoWeb.NoteIdLive do
  require Logger
  use VmemoWeb, :live_view

  alias Vmemo.PhotoService.TsNote

  # TODO:
  # alias VmemoWeb.Live.Components.WaterfallLc

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    user_id = socket.assigns.current_user.id
    {:ok, %{note: note, photos: photos}} = TsNote.get(id, :photos)

    if note == nil || note.belongs_to != Integer.to_string(user_id) do
      {:ok,
       socket
       |> assign(note: nil)
       |> assign(photos: [])
       |> assign_new(:note_form, fn ->
         to_form(%{
           "note" => ""
         })
       end)}
    else
      {:ok,
       socket
       |> assign(note: note)
       |> assign(photos: photos)
       |> assign_new(:form, fn ->
         to_form(%{
           "note" => note.text
         })
       end)}
    end
  end

  @impl true
  def handle_event("save", %{"note" => note_text}, socket) do
    # user_id = socket.assigns.current_user.id
    note_id = socket.assigns.note.id
    now = :os.system_time(:millisecond)

    TsNote.update(%{
      id: note_id,
      text: note_text,
      updated_at: now
    })

    {:noreply, socket |> put_flash(:info, "Updated")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="w-full mx-auto max-w-3xl p-4 sm:py-6">
      <%= if @note do %>
        <form phx-submit="save" class="flex flex-col space-y-4">
          <.live_component id="photos" module={VmemoWeb.Live.Components.WaterfallLc} items={@photos}>
            <:card :let={photo}>
              <.link navigate={~p"/photos/#{photo.id}"}>
                <.img src={photo.url} alt={photo.note} />
              </.link>
            </:card>
          </.live_component>

          <div class="flex flex-col space-y-2">
            <div class="mt-4">
              <.label for={@form[:note].id}>Note</.label>
              <textarea
                id={@form[:note].id}
                name={@form[:note].name}
                class="textarea textarea-bordered min-h-[3lh] "
              ><%= Phoenix.HTML.Form.normalize_value("textarea", @form[:note].value) %></textarea>
            </div>
          </div>
          <div class="text-sm text-gray-500">
            {@note.inserted_at}
          </div>

          <div>
            <.button>Save</.button>
          </div>
        </form>
      <% else %>
        <.not_found />
      <% end %>
    </section>
    """
  end
end
