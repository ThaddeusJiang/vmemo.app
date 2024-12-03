defmodule VmemoWeb.HelloComponent do
  use Surface.Component

  slot default, required: true

  def render(assigns) do
    ~F"""
    <h1 class="text-red-500">
      <#slot />
    </h1>
    """
  end
end
