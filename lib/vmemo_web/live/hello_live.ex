defmodule VmemoWeb.HelloLive do
  use Surface.LiveView

  alias VmemoWeb.HelloComponent

  def render(assigns) do
    ~F"""
    <div>
      <h1>Hello, LiveView!</h1>

      <HelloComponent>
        I am a slot content
      </HelloComponent>
    </div>
    """
  end
end
