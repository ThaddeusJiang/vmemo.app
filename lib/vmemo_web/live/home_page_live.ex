defmodule VmemoWeb.HomePageLive do
  require Logger
  use VmemoWeb, :live_view

  alias Vmemo.PhotoService.TsPhoto
  alias Vmemo.PhotoService

  alias VmemoWeb.Live.Components.WaterfallLc

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id

    socket =
      socket
      |> assign(:photos, load_photos("", 1, user_id))
      |> assign(:page, 1)
      |> assign(q: "")
      |> allow_upload(:photos,
        accept: ~w(.png .jpg .jpeg .gif),
        max_entries: 100
      )

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

  @impl true
  def handle_event("clean_photos", _params, socket) do
    socket =
      Enum.reduce(socket.assigns.uploads.photos.entries, socket, fn entry, acc_socket ->
        cancel_upload(acc_socket, :photos, entry.ref)
      end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :photos, ref)}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("upload", _params, socket) do
    user_id = socket.assigns.current_user.id

    # TODO: TDD
    # 1. create ts_note get note_id
    # 2. create ts_photo get photo_id
    # 3. update ts_note with photo_id
    # TODO: TDD
    # 1. get ts_photo with note_ids
    # 2. UI for note_ids (note_text as Title or summary)
    # 3. UI for note (show text and photos)
    case uploaded_entries(socket, :photos) do
      {[_ | _] = entries, []} ->
        _uploaded_photos =
          for entry <- entries do
            file_path =
              consume_uploaded_entry(socket, entry, fn %{path: path} ->
                filename = entry.uuid <> Path.extname(entry.client_name)

                {:ok, dest} = PhotoService.cp_file(path, user_id, filename)

                PhotoService.create_ts_photo(%{
                  image: read_image_base64(dest),
                  note: "",
                  url: Path.join("/", dest),
                  inserted_by: user_id |> Integer.to_string()
                })

                {:ok, dest}
              end)

            {:ok, file_path}
          end

        {
          :noreply,
          socket
          |> put_flash(:info, "Photos uploaded successfully")
          |> push_navigate(to: "/home")
          #  TODO: update the photos list
        }

      _ ->
        {:noreply, socket}
    end
  end

  defp load_photos(q, page, user_id) do
    TsPhoto.hybird_search_photos(q, user_id: user_id, page: page)
  end

  @impl true
  def handle_params(params, _uri, socket) do
    user_id = socket.assigns.current_user.id

    q = Map.get(params, "q", "")
    page = 1

    photos = load_photos(q, page, user_id)

    {:noreply,
     socket
     |> assign(:photos, photos)
     |> assign(:page, page)
     |> assign(:q, q)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="p-4 sm:py-6 grow" phx-drop-target={@uploads.photos.ref}>
      <form
        id="photos-upload-form"
        phx-submit="upload"
        phx-change="validate"
        phx-hook="ClipboardMediaFetcher"
      >
        <.modal
          :if={length(@uploads.photos.entries) > 0}
          id="photos-upload-modal"
          show
          on_cancel={JS.push("clean_photos")}
        >
          <.live_component
            id="upload-photos-preview"
            module={WaterfallLc}
            items={@uploads.photos.entries}
          >
            <:card :let={entry}>
              <article class="upload-entry relative">
                <figure>
                  <.live_img_preview entry={entry} />
                </figure>

                <%= case entry.progress do %>
                  <% 0 -> %>
                    <.button
                      type="button"
                      phx-click="cancel-upload"
                      phx-value-ref={entry.ref}
                      aria-label="cancel"
                      class="absolute top-1 right-1 btn btn-xs btn-circle btn-info"
                    >
                      &times;
                    </.button>
                  <% 100 -> %>
                    <div class="absolute inset-0 flex justify-center items-center backdrop-blur-sm ">
                      <div
                        class=" radial-progress text-white dark:text-black"
                        style="--value:100; --size:2rem; --thickness: 2px;"
                        role="progressbar"
                      >
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                          stroke-width="2"
                          class="size-6"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            d="m4.5 12.75 6 6 9-13.5"
                          />
                        </svg>
                      </div>
                    </div>
                  <% _ -> %>
                    <div class="absolute inset-0 flex justify-center items-center backdrop-blur-sm ">
                      <div
                        class=" radial-progress text-white dark:text-black"
                        style={"--value:#{entry.progress}; --size:2rem; --thickness: 2px;"}
                        role="progressbar"
                      >
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke-width="2"
                          stroke="currentColor"
                          class="size-6"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            d="m4.5 12.75 6 6 9-13.5"
                          />
                        </svg>
                      </div>
                    </div>
                <% end %>
              </article>
            </:card>
          </.live_component>

          <:header>
            <h2 class="text-lg font-semibold leading-none tracking-tight">Upload Photos</h2>
          </:header>

          <:footer>
            <.button>Upload</.button>
          </:footer>
        </.modal>
        <.live_file_input upload={@uploads.photos} accept="image/*" class="hidden" />
      </form>

      <div class="flex flex-col gap-4 w-full max-w-screen-lg mx-auto">
        <form action="/home" method="get">
          <input
            type="search"
            name="q"
            class="border border-zinc-200 rounded-lg px-2 py-1 text-zinc-900 w-full"
            placeholder="Search"
            value={@q}
          />
          <%!-- TODO: search when typing --%>
        </form>

        <.live_component id="waterfall-photos" module={WaterfallLc} items={@photos}>
          <:empty>
            <label
              for={@uploads.photos.ref}
              class="block mx-auto w-full text-center mt-4 hover:cursor-pointer"
            >
              <div class="  w-full h-full flex flex-col justify-center items-center">
                <img src="/images/undraw_images.svg" alt="Upload photos" class="w-1/2 h-auto" />
              </div>

              <p class="mt-4 text-xs text-gray-500">
                Drag and drop images here or click to upload
              </p>
            </label>
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

  def read_image_base64(file_path) do
    File.read!(file_path) |> Base.encode64()
  end
end
