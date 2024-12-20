defmodule VmemoWeb.LiveComponents.NoteUpdateForm do
  use VmemoWeb, :live_component

  alias VmemoWeb.Live.Components.Waterfall

  alias Vmemo.PhotoService.TsNote

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(%{
         "note" => assigns.note.text
       })
     end)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <form phx-submit="save" phx-target={@myself} class="flex flex-col space-y-4">
      <.live_component id="photos" module={Waterfall} items={@photos}>
        <:card :let={photo}>
          <.link navigate={~p"/photos/#{photo.id}"}>
            <.img src={photo.url} alt={photo.note} />
          </.link>
        </:card>
      </.live_component>

      <div class="flex flex-col space-y-2">
        <.textarea_field
          id={@form[:note].id}
          name={@form[:note].name}
          value={@form[:note].value}
          label="Note"
          errors={@form[:note].errors}
        />
      </div>

      <div class="text-sm text-gray-500">
        {@note.inserted_at}
      </div>

      <div>
        <.button>Save</.button>
      </div>
    </form>
    """
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

    {:noreply, socket |> put_flash(:info, "Updated") |> push_patch(to: socket.assigns.patch)}
  end
end
