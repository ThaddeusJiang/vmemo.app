defmodule Vmemo.PhotoService.TsPhoto do
  @moduledoc """
  A module to interact with the photo collection in Typesense.

  CRUD and search operations are supported.
  """

  require Logger
  alias SmallSdk.Typesense

  @collection_name "photos"

  def create_photo(photo) do
    Typesense.create_document("photos", photo)
  end

  def get_photo(photo_id) do
    Typesense.get_document("photos", photo_id)
  end

  def update_photo(photo) do
    Typesense.update_document("photos", photo)
  end

  def list_photos() do
    req = Typesense.build_request("/collections/photos/documents/search")

    res =
      Req.get(req,
        params: [
          q: "",
          query_by: "note",
          exclude_fields: "image_embedding",
          # TODO: inserted_by: "user_id",
          # filter_by: "is_public:true",
          page: 1,
          per_page: 100,
          sort_by: "inserted_at:desc"
        ]
      )

    {:ok, data} = Typesense.handle_response(res)

    data["hits"] |> Enum.map(&Map.get(&1, "document")) || []
  end

  def list_similar_photos(id) do
    req = Typesense.build_request("/multi_search")

    res =
      Req.post(req,
        json: %{
          "searches" => [
            %{
              "collection" => "photos",
              "q" => "*",
              "vector_query" => "image_embedding:([], id:#{id})"
            }
          ]
        }
      )

    {:ok, data} = Typesense.handle_response(res)

    data["results"] |> hd() |> Map.get("hits") |> Enum.map(&Map.get(&1, "document"))
  end

  def create_collection_photos_20241203() do
    schema = %{
      "name" => @collection_name,
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

  defp drop_collection_photos() do
    Typesense.drop_collection(@collection_name)
  end

  def reset() do
    drop_collection_photos()
    create_collection_photos_20241203()
  end
end
