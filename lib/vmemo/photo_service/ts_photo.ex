defmodule Vmemo.PhotoService.TsPhoto do
  @moduledoc """
  A module to interact with the photo collection in Typesense.

  CRUD and search operations are supported.
  """

  require Logger
  alias SmallSdk.Typesense

  @collection_name "photos"

  defstruct [:id, :image, :note, :url, :file_id, :inserted_at, :inserted_by]

  def parse(nil) do
    nil
  end

  def parse(photo) do
    %__MODULE__{
      id: photo["id"],
      image: photo["image"],
      note: photo["note"],
      url: photo["url"],
      file_id: photo["file_id"],
      inserted_at: photo["inserted_at"],
      inserted_by: photo["inserted_by"]
    }
  end

  def create_photo(photo) do
    Typesense.create_document(@collection_name, photo)
  end

  def get_photo(id) do
    {:ok, photo} = Typesense.get_document(@collection_name, id)

    photo |> parse()
  end

  def update_photo(photo) do
    Typesense.update_document(@collection_name, photo)
  end

  def update_note(id, note) do
    update_photo(%{
      id: id,
      note: note
    })
  end

  def list_photos(opts \\ []) do
    user_id = Keyword.get(opts, :user_id, "")
    req = Typesense.build_request("/collections/photos/documents/search")

    res =
      Req.get(req,
        params: [
          q: "",
          query_by: "note",
          exclude_fields: "image_embedding",
          filter_by: "inserted_by:#{user_id}",
          page: 1,
          per_page: 100,
          sort_by: "inserted_at:desc"
        ]
      )

    {:ok, photos} = Typesense.handle_search_res(res)

    photos
  end

  def hybird_search_photos(q, opts \\ []) do
    user_id = Keyword.get(opts, :user_id, "")
    page = Keyword.get(opts, :page, 1)
    per_page = 10

    req = Typesense.build_request("/multi_search")

    res =
      Req.post(req,
        json: %{
          "searches" => [
            %{
              "query_by" => "note, image_embedding",
              "q" => q,
              "collection" => "photos",
              "filter_by" => "inserted_by:#{user_id}",
              "exclude_fields" => "image_embedding",
              "page" => page,
              "per_page" => per_page,
              "sort_by" => "_text_match:desc,_vector_distance:asc,inserted_at:desc"
            }
          ]
        }
      )

    {:ok, photos} = Typesense.handle_multi_search_res(res)

    photos |> Enum.map(&parse/1)
  end

  def list_similar_photos(id, opts \\ []) do
    user_id = Keyword.get(opts, :user_id, "")
    req = Typesense.build_request("/multi_search")

    res =
      Req.post(req,
        json: %{
          "searches" => [
            %{
              "collection" => "photos",
              "q" => "*",
              "vector_query" => "image_embedding:([], id:#{id})",
              "filter_by" => "inserted_by:#{user_id}",
              "exclude_fields" => "image_embedding"
            }
          ]
        }
      )

    {:ok, photos} = Typesense.handle_multi_search_res(res)

    photos |> Enum.map(&parse/1)
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

  def setup() do
    res = create_collection_photos_20241203()
    Logger.info("Collection created: #{inspect(res)}")
  end

  def reset() do
    drop_collection_photos()
    setup()
  end
end
