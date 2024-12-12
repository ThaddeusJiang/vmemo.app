defmodule VmemoWeb.PhotoUploadLive do
  use VmemoWeb, :live_view

  alias Vmemo.PhotoService

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
  def handle_event("save", _params, socket) do
    user_id = socket.assigns.current_user.id

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
    <form
      id="upload-form"
      phx-submit="save"
      phx-change="validate"
      class="h-81 mx-auto w-full sm:max-w-screen-sm"
      phx-hook="ClipboardMediaFetcher"
    >
      <%!-- use phx-drop-target with the upload ref to enable file drag and drop --%>
      <label for={@uploads.photos.ref} class="relative h-auto">
        <section
          phx-drop-target={@uploads.photos.ref}
          class=" aspect-auto sm:aspect-video relative flex flex-col w-full rounded-lg border bg-base-200 border-gray-300 p-4 text-center hover:border-gray-400 hover:bg-gray-100 hover:shadow-inner hover:cursor-pointer focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 "
        >
          <div
            :if={@uploads.photos.entries != []}
            class="grow grid gap-1 grid-cols-2 sm:grid-cols-3 md:grid-cols-4 "
          >
            <article
              :for={{entry, index} <- Enum.with_index(@uploads.photos.entries, 1)}
              class="upload-entry relative"
            >
              <figure>
                <.live_img_preview
                  entry={entry}
                  class={"h-auto w-full object-cover rounded"
                      <> if entry.progress > 0 and entry.progress < 100, do: "opacity-50" , else: ""}
                />
              </figure>
              <%= if entry.progress == 0 do %>
                <button
                  type="button"
                  phx-click="cancel-upload"
                  phx-value-ref={entry.ref}
                  aria-label="cancel"
                  class="absolute top-2 right-1 btn btn-xs btn-circle btn-info"
                >
                  <%= index %>
                </button>
              <% else %>
                <div class="absolute inset-0  flex justify-center items-center">
                  <div
                    class=" radial-progress text-white dark:text-black"
                    style={"--value:#{entry.progress}; --size:2rem; --thickness: 4px;"}
                    role="progressbar"
                  >
                    <span class="sr-only">Uploading...</span>
                  </div>
                </div>
              <% end %>
            </article>
          </div>

          <.live_file_input upload={@uploads.photos} accept="image/*" class="hidden" />
          <div
            :if={@uploads.photos.entries == []}
            class=" justify-self-center grow flex flex-col justify-center"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="currentColor"
              class="w-12 h-12 mx-auto"
            >
              <path d="M1 14.5C1 12.1716 2.22429 10.1291 4.06426 8.9812C4.56469 5.044 7.92686 2 12 2C16.0731 2 19.4353 5.044 19.9357 8.9812C21.7757 10.1291 23 12.1716 23 14.5C23 17.9216 20.3562 20.7257 17 20.9811L7 21C3.64378 20.7257 1 17.9216 1 14.5ZM16.8483 18.9868C19.1817 18.8093 21 16.8561 21 14.5C21 12.927 20.1884 11.4962 18.8771 10.6781L18.0714 10.1754L17.9517 9.23338C17.5735 6.25803 15.0288 4 12 4C8.97116 4 6.42647 6.25803 6.0483 9.23338L5.92856 10.1754L5.12288 10.6781C3.81156 11.4962 3 12.927 3 14.5C3 16.8561 4.81833 18.8093 7.1517 18.9868L7.325 19H16.675L16.8483 18.9868ZM13 13V17H11V13H8L12 8L16 13H13Z">
              </path>
            </svg>

            <label
              for={@uploads.photos.ref}
              class="block flex-none py-[2px] rounded-full place-content-center  hover:cursor-pointer"
            >
              <span class="text-xs text-gray-500">
                Drag and drop images here or click to upload
              </span>
            </label>
          </div>
        </section>
      </label>

      <p :for={err <- upload_errors(@uploads.photos)} class="alert alert-danger">
        <%= error_to_string(err) %>
      </p>

      <footer :if={Enum.count(@uploads.photos.entries) > 0} class="flex justify-center mt-4">
        <.button>Upload</.button>
      </footer>
    </form>
    """
  end

  def read_image_base64(file_path) do
    File.read!(file_path) |> Base.encode64()
  end
end
