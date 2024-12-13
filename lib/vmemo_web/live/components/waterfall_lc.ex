defmodule VmemoWeb.Live.Components.WaterfallLc do
  use VmemoWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:window_width, 0)
     |> assign(:col, 1)
     |> assign(:items, [])}
  end

  @impl true
  def update(assigns, socket) do
    {:ok, socket |> assign(assigns)}
  end

  @impl true
  def handle_event("window_resize", %{"width" => width}, socket) do
    col =
      cond do
        width >= 1024 -> 5
        width >= 768 -> 4
        width >= 640 -> 3
        true -> 2
      end

    send(self(), {:window_resize, width})

    {:noreply,
     socket
     |> assign(:window_width, width)
     |> assign(:col, col)}
  end

  def split_list(list, n) do
    list
    |> Enum.with_index()
    |> Enum.group_by(fn {_elem, index} -> rem(index, n) end)
    |> Enum.map(fn {_key, group} -> Enum.map(group, &elem(&1, 0)) end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full h-full">
      <%= if Enum.empty?(@items) do %>
        <%= if @empty do %>
          {render_slot(@empty)}
        <% else %>
          <div class="text-center text-gray-500 mt-5">No photos found.</div>
        <% end %>
      <% else %>
        <div id={@id} phx-hook="WindowResizer" phx-target={@myself}>
          <div class={[
            "grid gap-3",
            case @col do
              5 -> "grid-cols-5"
              4 -> "grid-cols-4"
              3 -> "grid-cols-3"
              2 -> "grid-cols-2"
              _ -> "hidden"
            end
          ]}>
            <div :for={items <- @items |> split_list(@col)} class="space-y-3">
              <%= for item <- items do %>
                {render_slot(@card, item)}
              <% end %>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
