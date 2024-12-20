defmodule VmemoWeb.PhotoUploadLive do
  use VmemoWeb, :live_view

  alias VmemoWeb.LiveComponents.UploadForm

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%!-- <section class="p-4 sm:py-6" phx-drop-target={@uploads.photos.ref}> --%>
    <section class="p-4 sm:py-6">
      <.live_component id="upload_form" module={UploadForm} current_user={@current_user} />
    </section>
    """
  end
end
