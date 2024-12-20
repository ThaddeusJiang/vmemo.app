defmodule Vmemo.Ts do
  alias SmallSdk.Typesense

  @doc """
  2024-12-20
  create photos collection
  """
  def change_1() do
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

  @doc """
  2024-12-20
  create notes collection, add note_ids to photos collection
  """
  def change_2() do
    notes_schema = %{
      "name" => "notes",
      "fields" => [
        %{"name" => "text", "type" => "string"},
        %{"name" => "photo_ids", "type" => "string[]", "optional" => true, "facet" => true},
        %{"name" => "inserted_at", "type" => "int64"},
        %{"name" => "updated_at", "type" => "int64"},
        %{"name" => "belongs_to", "type" => "string", "facet" => true}
      ],
      "default_sorting_field" => "inserted_at"
    }

    Typesense.create_collection(notes_schema)

    photos_schema = %{
      "fields" => [
        %{"name" => "note_ids", "type" => "string[]", "optional" => true, "facet" => true}
      ]
    }

    Typesense.update_collection("photos", photos_schema)
  end

  def reset do
    Typesense.drop_collection("photos")
    Typesense.drop_collection("notes")

    change_1()
    change_2()
  end
end
