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

    IO.inspect(photos, label: "debug")

    if note == nil || note.belongs_to != Integer.to_string(user_id) do
      {:ok, socket |> assign(note: nil) |> assign(photos: [])}
    else
      {:ok,
       socket
       |> assign(note: note)
       |> assign(photos: photos)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="w-full mx-auto max-w-screen-md p-4 sm:py-6">
      <%= if @note do %>
        <div class="flex flex-col space-y-4">
          <div class="flex flex-col space-y-2">
            <div class="text-lg font-bold">
              {@note.text}
            </div>
            <div class="text-sm text-gray-500">
              {@note.inserted_at}
            </div>
          </div>

          <%!-- <section class="grid gap-3 grid-cols-3">
            <.img :for={photo <- @photos} src={photo.url} alt={photo.note} />
          </section> --%>
        </div>
      <% else %>
        <.not_found />
      <% end %>
    </section>
    """
  end
end
