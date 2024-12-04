defmodule VmemoWeb.PhotoIdLive do
  use VmemoWeb, :live_view

  alias Vmemo.PhotoService.TsPhoto

  @impl true
  def mount(
        %{
          "id" => id
        },
        _session,
        socket
      ) do
    {:ok, photo} = TsPhoto.get_photo(id)

    socket = assign(socket, photo: photo)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container">
      <div class="grid grid-cols-1 gap-4">
        <div class="space-y-4">
          <img
            src={@photo["url"]}
            alt={@photo["note"]}
            class="w-full h-auto object-cover rounded shadow"
          />
        </div>
      </div>
    </div>
    """
  end
end
