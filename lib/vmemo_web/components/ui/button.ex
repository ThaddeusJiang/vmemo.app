defmodule VmemoWeb.Ui.Button do
  use Surface.Component

  slot default, required: true

  prop type, :string, default: "button", values: ["button", "submit", "reset"]
  prop variant, :string, default: "outline", values: ["outline", "primary", "danger"]

  def render(assigns) do
    ~F"""
    <button
      type={@type}
      class={"btn " <>
        case @variant do
          "outline" -> "btn-outline"
          "primary" -> "btn-accent"
          "danger" -> "btn-error"
          _ -> ""
        end}
    >
      <#slot />
    </button>
    """
  end
end
