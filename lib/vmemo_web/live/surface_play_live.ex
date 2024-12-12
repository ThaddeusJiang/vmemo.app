defmodule VmemoWeb.SurfacePlayLive do
  use VmemoWeb, :surface_live_view

  alias VmemoWeb.Ui.Box
  alias VmemoWeb.Ui.Button
  alias VmemoWeb.HelloComponent

  def render(assigns) do
    ~F"""
    <div>
      <h1>Hello, LiveView!</h1>

      <HelloComponent>
        I am a slot content
      </HelloComponent>

      <Box>
        hello, box
      </Box>

      <Button type="submit">
        Click me
      </Button>

      <div class="flex flex-col space-y-4 justify-start">
        <h1>buttons</h1>

        <.button>
          save
        </.button>

        <.button variant="ghost">
          cancel button
        </.button>

        <.button variant="outline">
          outline button
        </.button>

        <.button disabled>
          disabled button
        </.button>

        <.button variant="danger">
          danger button
        </.button>
      </div>
    </div>
    """
  end
end
