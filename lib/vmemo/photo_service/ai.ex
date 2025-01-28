defmodule Vmemo.PhotoService.Ai do
  require Logger

  alias SmallSdk.FileSystem
  alias SmallSdk.Ollama

  def gen_description(image_path) do
    # TDD:
    # read the image file
    # base64 encode the image
    # call the AI service
    # return the description

    image_base64 = FileSystem.read_image_base64(Path.join([".", image_path]))

    {:ok, res} =
      Ollama.complete(%{
        model: "llama3.2-vision",
        prompt: "Describe the image in Chinese",
        stream: false,
        images: [image_base64]
      })

    {:ok, res["response"]}
  end
end
