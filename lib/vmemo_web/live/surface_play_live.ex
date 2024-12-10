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
    </div>
    """
  end
end
