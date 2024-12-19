defmodule VmemoWeb.PhotoUploadLive do
  use VmemoWeb, :live_view

  alias Vmemo.PhotoService
  alias Vmemo.PhotoService.TsNote
  alias VmemoWeb.Live.Components.WaterfallLc

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> allow_upload(:photos,
        accept: ~w(.png .jpg .jpeg .gif),
        max_entries: 100
        # max_files: 5,
        # max_file_size: 10_000_000
      )
      |> assign_new(:upload_form, fn ->
        to_form(%{
          "note" => ""
        })
      end)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :photos, ref)}
  end

  @impl true
  def handle_event(
        "save",
        %{"note" => note_text},
        socket
      ) do
    user_id = socket.assigns.current_user.id

    # TODO: TDD
    # 1. create ts_note get note_id
    {:ok, note} =
      TsNote.create(%{
        text: note_text,
        belongs_to: user_id |> Integer.to_string()
      })

    # 2. create ts_photo get photo_id
    # 3. update ts_note with photo_id
    # TODO: TDD
    # 1. get ts_photo with note_ids
    # 2. UI for note_ids (note_text as Title or summary)
    # 3. UI for note (show text and photos)

    case uploaded_entries(socket, :photos) do
      {[_ | _] = entries, []} ->
        ts_photos =
          for entry <- entries do
            ts_photo =
              consume_uploaded_entry(socket, entry, fn %{path: path} ->
                filename = entry.uuid <> Path.extname(entry.client_name)

                {:ok, dest} = PhotoService.cp_file(path, user_id, filename)

                {:ok, ts_photo} =
                  PhotoService.create_ts_photo(%{
                    image: read_image_base64(dest),
                    note: note_text,
                    note_ids: [note["id"]],
                    url: Path.join("/", dest),
                    inserted_by: user_id |> Integer.to_string()
                  })

                {:ok, ts_photo}
              end)

            ts_photo
          end

        TsNote.update_photo_ids(note["id"], Enum.map(ts_photos, & &1["id"]))

        {:noreply,
         socket
         |> put_flash(:info, "Photos uploaded successfully")
         |> push_navigate(to: "/photos")}

      _ ->
        {:noreply, socket}
    end
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

  @impl true
  def render(assigns) do
    ~H"""
    <section class="p-4 sm:py-6" phx-drop-target={@uploads.photos.ref}>
      <form
        id="upload-form"
        phx-submit="save"
        phx-change="validate"
        class=" w-full mx-auto max-w-sm"
        phx-hook="ClipboardMediaFetcher"
      >
        <%!-- use phx-drop-target with the upload ref to enable file drag and drop --%>
        <label for={@uploads.photos.ref} class="relative h-auto">
          <section class=" aspect-auto sm:aspect-video relative flex flex-col w-full rounded-lg border bg-base-100 border-gray-300 p-4 text-center hover:border-gray-400 hover:bg-base-200 hover:shadow-inner hover:cursor-pointer focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 ">
            <.live_component
              id="waterfall-upload-photos"
              module={WaterfallLc}
              items={@uploads.photos.entries}
            >
              <:empty>
                <div class="  w-full h-full flex flex-col justify-center items-center">
                  <img src="/images/undraw_images.svg" alt="Upload photos" class="w-1/2 h-auto" />
                </div>
              </:empty>

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

            <label
              for={@uploads.photos.ref}
              class="block flex-none py-[2px] rounded-full place-content-center  hover:cursor-pointer"
            >
              <span class="text-xs text-gray-500">
                Drag and drop images here or click to upload
              </span>
            </label>

            <.live_file_input upload={@uploads.photos} accept="image/*" class="hidden" />
          </section>
        </label>

        <p :for={err <- upload_errors(@uploads.photos)} class="alert alert-danger">
          {error_to_string(err)}
        </p>

        <div :if={Enum.count(@uploads.photos.entries) > 0} class="mt-4">
          <.label for={@upload_form[:note].id}>Note</.label>
          <textarea
            id={@upload_form[:note].id}
            name={@upload_form[:note].name}
            class="textarea textarea-bordered min-h-[3lh] "
          ><%= Phoenix.HTML.Form.normalize_value("textarea", @upload_form[:note].value) %></textarea>
        </div>

        <footer :if={Enum.count(@uploads.photos.entries) > 0} class="flex justify-center mt-4">
          <.button>Upload</.button>
        </footer>
      </form>
    </section>
    """
  end

  def read_image_base64(file_path) do
    File.read!(file_path) |> Base.encode64()
  end
end
