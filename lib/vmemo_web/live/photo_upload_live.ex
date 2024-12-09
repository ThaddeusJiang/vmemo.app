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
    <div class="w-full h-full flex justify-center items-center">
      <form id="upload-form" phx-submit="save" phx-change="validate" class="container h-auto min-h-80">
        <%!-- use phx-drop-target with the upload ref to enable file drag and drop --%>
        <label for={@uploads.photos.ref} class="relative h-auto">
          <section
            phx-drop-target={@uploads.photos.ref}
            class=" aspect-video relative flex flex-col w-full rounded-lg border bg-base-200 border-gray-300 p-4 text-center hover:border-gray-400 hover:shadow-inner hover:cursor-pointer focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 "
          >
            <div class="grid gap-1 grid-cols-2 sm:grid-cols-3 md:grid-cols-4 ">
              <%= for {entry, index} <- Enum.with_index(@uploads.photos.entries, 1) do %>
                <article class="upload-entry relative">
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
                      class="absolute top-2 right-1 text-white bg-blue-500 rounded-full w-6 h-6 flex items-center justify-center"
                    >
                      <%= index %>
                    </button>
                  <% else %>
                    <div class="absolute inset-0  flex justify-center items-center">
                      <div
                        class=" radial-progress text-white dark:text-black"
                        style={"--value:#{entry.progress}; --size:2rem; --thickness: 2px;"}
                        role="progressbar"
                      >
                        <span class="sr-only">Uploading...</span>
                      </div>
                    </div>
                  <% end %>
                </article>
              <% end %>
            </div>

            <.live_file_input upload={@uploads.photos} class="hidden" />
            <label class="block py-[2px] rounded-full place-content-center ">
              Drop media to reorder
            </label>
          </section>
        </label>
        <%!-- Phoenix.Component.upload_errors/1 returns a list of error atoms --%>
        <%= for err <- upload_errors(@uploads.photos) do %>
          <p class="alert alert-danger"><%= error_to_string(err) %></p>
        <% end %>

        <footer :if={Enum.count(@uploads.photos.entries) > 0} class="flex justify-center mt-4">
          <.button>Upload</.button>
        </footer>
      </form>
    </div>
    """
  end

  def read_image_base64(file_path) do
    File.read!(file_path) |> Base.encode64()
  end
end
