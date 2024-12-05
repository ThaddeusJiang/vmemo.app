# mix run priv/ts/seeds.exs

# TODO: elixir style TDD:
Vmemo.PhotoService.TsPhoto.create_photo(%{
  "id" => "1",
  "note" => "A photo of a cat",
  "image_embedding" => [0.1, 0.2, 0.3]
})
