defmodule VmemoWeb.HomePageLive do
  require Logger

  alias SmallSdk.FileSystem
  use VmemoWeb, :live_view

  alias Vmemo.PhotoService
  alias Vmemo.PhotoService.TsPhoto

  alias VmemoWeb.LiveComponents.Waterfall
  alias VmemoWeb.LiveComponents.UploadForm

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:search_by_photo, nil)
     |> assign(show_expanded: false)
     |> allow_upload(:photo,
       accept: ~w(.png .jpg .jpeg .gif .svg .webp),
       progress: &handle_progress/3,
       auto_upload: true,
       max_entries: 1
     )}
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

  @impl true
  def handle_event("validate", _, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("search_by_photo", _, socket) do
    {:noreply, socket}
  end

  defp handle_progress(:photo, entry, socket) do
    user_id = socket.assigns.current_user.id

    if entry.done? do
      uploaded_file =
        consume_uploaded_entry(socket, entry, fn %{path: path} = _meta ->
          filename = entry.uuid <> Path.extname(entry.client_name)

          {:ok, dest} = PhotoService.cp_file(path, socket.assigns.current_user.id, filename)

          {:ok, ts_photo} =
            TsPhoto.create(%{
              image: FileSystem.read_image_base64(dest),
              note: "",
              note_ids: [],
              url: Path.join("/", dest),
              inserted_by: user_id |> Integer.to_string()
            })

          {:ok, ts_photo}
        end)

      {:noreply,
       socket |> push_navigate(to: ~p"/photos/#{uploaded_file.id}?action=search", replace: true)}
    else
      {:noreply, socket}
    end
  end

  defp load_photos(q, page, user_id) do
    TsPhoto.hybird_search_photos({q, nil}, user_id: user_id, page: page)
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
        <form
          :if={@photos != [] and !@show_expanded}
          action="/home"
          method="get"
          class="form-control max-w-sm"
        >
          <label class="input input-bordered flex items-center gap-2 rounded-3xl">
            <input type="search" name="q" class=" grow" placeholder="Search" value={@q} />

            <div class="flex items-center gap-2">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
                class="size-6 hover:cursor-pointer hover:opacity-80"
                phx-click="show_expanded"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M7.5 3.75H6A2.25 2.25 0 0 0 3.75 6v1.5M16.5 3.75H18A2.25 2.25 0 0 1 20.25 6v1.5m0 9V18A2.25 2.25 0 0 1 18 20.25h-1.5m-9 0H6A2.25 2.25 0 0 1 3.75 18v-1.5M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"
                />
              </svg>
            </div>
          </label>
          <%!-- TODO: search when typing --%>
        </form>

        <div
          :if={@show_expanded}
          class="flex flex-col gap-2 relative border border-base-300 rounded-3xl p-4 max-w-sm"
        >
          <header class="w-full flex items-center justify-center">
            <p class="text-gray-500">Search any image</p>
            <.button
              variant="ghost"
              phx-click="hide_extened"
              class="btn-circle absolute top-2 right-2"
            >
              &times;
            </.button>
          </header>
          <form
            id="search-by-photo"
            class="form-control flex flex-col items-center justify-center gap-4"
            phx-submit="search_by_photo"
            phx-change="validate"
            phx-drop-target={@uploads.photo.ref}
          >
            <label for={@uploads.photo.ref}>
              <div class="  w-full h-full flex flex-col justify-center items-center">
                <img src="/images/undraw_images.svg" alt="Upload photos" class="h-20 w-auto" />
              </div>
              <span class="text-xs text-gray-500">
                Drag an image here or <span class="link  link-hover link-info">upload a file</span>
              </span>

              <.live_file_input upload={@uploads.photo} accept="image/*" class="hidden" />
            </label>
          </form>
        </div>

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
