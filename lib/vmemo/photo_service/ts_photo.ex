defmodule Vmemo.PhotoService.TsPhoto do
  @moduledoc """
  A module to interact with the photo collection in Typesense.

  CRUD and search operations are supported.
  """

  require Logger
  alias SmallSdk.Typesense

  @collection_name "photos"

  defstruct [:id, :image, :note, :note_ids, :url, :file_id, :inserted_at, :inserted_by]

  def parse(nil) do
    nil
  end

  def parse(photo) do
    %__MODULE__{
      id: photo["id"],
      image: photo["image"],
      note: photo["note"],
      note_ids: photo["note_ids"],
      url: photo["url"],
      file_id: photo["file_id"],
      inserted_at: photo["inserted_at"],
      inserted_by: photo["inserted_by"]
    }
  end

  def create(photo) do
    now = DateTime.utc_now() |> DateTime.to_unix()

    {:ok, document} =
      Typesense.create_document(
        @collection_name,
        Map.put_new(photo, :inserted_at, now)
      )

    {:ok, parse(document)}
  end

  def get_photo(id) do
    {:ok, photo} = Typesense.get_document(@collection_name, id)

    case photo do
      nil -> nil
      _ -> parse(photo)
    end
  end

  def get(id, :notes) do
    {:ok, photo} = Typesense.get_document(@collection_name, id)

    photo =
      case photo do
        nil -> nil
        _ -> parse(photo)
      end

    req = Typesense.build_request("/collections/notes/documents/search")

    res =
      Req.get(req,
        params: [
          q: "*",
          filter_by: "photo_ids:#{id}"
        ]
      )

    {:ok, notes} = Typesense.handle_search_res(res)

    {:ok, %{photo: photo, notes: notes |> Enum.map(&Vmemo.PhotoService.TsNote.parse/1)}}
  end

  def update_photo(photo) do
    Typesense.update_document(@collection_name, photo)
  end

  def delete_photo(id) do
    Typesense.delete_document(@collection_name, id)
  end

  def update_note(id, note) do
    update_photo(%{
      id: id,
      note: note
    })
  end

  def list_photos(opts \\ []) do
    user_id = Keyword.get(opts, :user_id, "")
    req = Typesense.build_request("/collections/#{@collection_name}/documents/search")

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

    q =
      case String.trim(q) do
        "" -> "*"
        q -> q
      end

    req = Typesense.build_request("/multi_search")

    res =
      Req.post(req,
        json: %{
          "searches" => [
            %{
              "query_by" => "note,image_embedding",
              "q" => q,
              "collection" => @collection_name,
              "filter_by" => "inserted_by:#{user_id}",
              "vector_query" => "image_embedding:([], k: 200, distance_threshold: 0.79)",
              "exclude_fields" => "image_embedding",
              "sort_by" => "_text_match:desc,inserted_at:desc",
              "per_page" => per_page,
              "page" => page
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
              "collection" => @collection_name,
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
end
