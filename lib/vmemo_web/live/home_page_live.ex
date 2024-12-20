defmodule VmemoWeb.HomePageLive do
  require Logger
  use VmemoWeb, :live_view

  alias Vmemo.PhotoService.TsPhoto

  alias VmemoWeb.LiveComponents.Waterfall
  alias VmemoWeb.LiveComponents.UploadForm

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("load_more", _, socket) do
    user_id = socket.assigns.current_user.id
    q = socket.assigns.q

    page = socket.assigns.page + 1
    more_photos = load_photos(q, page, user_id)

    {:noreply,
     socket
     |> update(:photos, &(&1 ++ more_photos))
     |> assign(:page, page)}
  end

  defp load_photos(q, page, user_id) do
    TsPhoto.hybird_search_photos(q, user_id: user_id, page: page)
  end

  @impl true
  def handle_params(params, _uri, socket) do
    user_id = socket.assigns.current_user.id

    q = Map.get(params, "q", "")

    photos = load_photos(q, 1, user_id)

    {:noreply,
     socket
     |> assign(:photos, photos)
     |> assign(:page, 1)
     |> assign(:q, q)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="p-4 sm:py-6 lg:px-8 grow">
      <div class="flex flex-col gap-4 w-full max-w-screen-lg mx-auto">
        <form :if={@photos != []} action="/home" method="get">
          <input
            type="search"
            name="q"
            class="border border-zinc-200 rounded-lg px-2 py-1 text-zinc-900 w-full"
            placeholder="Search"
            value={@q}
          />
          <%!-- TODO: search when typing --%>
        </form>

        <.live_component id="waterfall-photos" module={Waterfall} items={@photos}>
          <:empty>
            <.live_component id="upload-form" module={UploadForm} current_user={@current_user} />
          </:empty>

          <:card :let={photo}>
            <.link navigate={~p"/photos/#{photo.id}"} class="link link-hover block">
              <.img src={photo.url} alt={photo.note} id={photo.id} />
            </.link>
          </:card>
        </.live_component>

        <div phx-hook="InfiniteScroll" id="infinite-scroll"></div>
      </div>
    </section>
    """
  end
end
