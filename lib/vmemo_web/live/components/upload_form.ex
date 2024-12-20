defmodule VmemoWeb.LiveComponents.UploadForm do
  use VmemoWeb, :live_component

  alias VmemoWeb.LiveComponents.Waterfall

  alias Vmemo.PhotoService
  alias Vmemo.PhotoService.TsNote
  alias Vmemo.PhotoService.TsPhoto

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> allow_upload(:photos,
       accept: ~w(.png .jpg .jpeg .gif),
       max_entries: 100
     )}
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(%{
         "note" => ""
       })
     end)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <form
      id="upload-form"
      phx-target={@myself}
      phx-submit="save"
      phx-change="validate"
      class=" w-full mx-auto max-w-sm"
      phx-hook="ClipboardMediaFetcher"
      phx-drop-target={@uploads.photos.ref}
    >
      <%!-- use phx-drop-target with the upload ref to enable file drag and drop --%>
      <label for={@uploads.photos.ref} class="relative h-auto">
        <section class=" aspect-auto sm:aspect-video relative flex flex-col w-full rounded-lg border bg-base-100 border-gray-300 p-4 text-center hover:border-gray-400 hover:bg-base-200 hover:shadow-inner hover:cursor-pointer focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 ">
          <.live_component
            id="waterfall-upload-photos"
            module={Waterfall}
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
                      phx-target={@myself}
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
        <.label for={@form[:note].id}>Note</.label>
        <textarea
          id={@form[:note].id}
          name={@form[:note].name}
          class="textarea textarea-bordered min-h-[3lh] "
        ><%= Phoenix.HTML.Form.normalize_value("textarea", @form[:note].value) %></textarea>
      </div>

      <footer :if={Enum.count(@uploads.photos.entries) > 0} class="flex justify-center mt-4">
        <.button>Upload</.button>
      </footer>
    </form>
    """
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

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

    {:ok, note} =
      TsNote.create(%{
        text: note_text,
        belongs_to: user_id |> Integer.to_string()
      })

    case uploaded_entries(socket, :photos) do
      {[_ | _] = entries, []} ->
        ts_photos =
          for entry <- entries do
            ts_photo =
              consume_uploaded_entry(socket, entry, fn %{path: path} ->
                filename = entry.uuid <> Path.extname(entry.client_name)

                {:ok, dest} = PhotoService.cp_file(path, user_id, filename)

                {:ok, ts_photo} =
                  TsPhoto.create(%{
                    image: read_image_base64(dest),
                    note: note_text,
                    note_ids: [note.id],
                    url: Path.join("/", dest),
                    inserted_by: user_id |> Integer.to_string()
                  })

                {:ok, ts_photo}
              end)

            ts_photo
          end

        TsNote.update_photo_ids(note.id, Enum.map(ts_photos, & &1.id))

        {:noreply,
         socket
         |> put_flash(:info, "Photos uploaded successfully")
         |> push_navigate(to: "/photos")}

      _ ->
        {:noreply, socket}
    end
  end

  def read_image_base64(file_path) do
    File.read!(file_path) |> Base.encode64()
  end
end
