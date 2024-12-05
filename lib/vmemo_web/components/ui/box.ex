defmodule VmemoWeb.Ui.Box do
  use Surface.Component

  slot default, required: true

  def render(assigns) do
    ~F"""
    <div class="p-4">
      <#slot />
    </div>
    """
  end
end
