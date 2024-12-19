defmodule Vmemo.Ts.Migrateion20241203 do
  def define() do
    schema = %{
      "name" => "photos",
      "fields" => [
        %{"name" => "image", "type" => "image", "store" => false},
        %{"name" => "note", "type" => "string", "optional" => true},
        %{"name" => "url", "type" => "string"},
        %{"name" => "file_id", "type" => "string", "optional" => true},
        %{"name" => "inserted_at", "type" => "int64"},
        %{"name" => "inserted_by", "type" => "string"},
        # embedding
        %{
          "name" => "image_embedding",
          "type" => "float[]",
          "embed" => %{
            "from" => ["image"],
            "model_config" => %{
              "model_name" => "ts/clip-vit-b-p32"
            }
          }
        }
      ],
      "default_sorting_field" => "inserted_at"
    }

    Typesense.create_collection(schema)
  end

  def data() do
    IO.puts("Migrate photos")
  end
end
