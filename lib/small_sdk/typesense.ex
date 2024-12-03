defmodule SmallSdk.Typesense do
  require Logger

  ###
  # Collections start
  ###
  def create_collection(schema) do
    req = build_request("/collections")
    res = Req.post(req, json: schema)

    handle_response(res)
  end

  def get_collection(collection_name) do
    req = build_request("/collections/#{collection_name}")
    res = Req.get(req)

    handle_response(res)
  end

  def update_collection(collection_name, schema) do
    req = build_request("/collections/#{collection_name}")
    res = Req.patch(req, json: schema)

    handle_response(res)
  end

  def drop_collection(collection_name) do
    req = build_request("/collections/#{collection_name}")
    res = Req.delete(req)

    handle_response(res)
  end

  def list_collections() do
    req = build_request("/collections")
    res = Req.get(req)

    handle_response(res)
  end

  ###
  # Collections end
  ###

  ###
  # Documents start
  ###

  def create_document(collection_name, document) do
    req = build_request("/collections/#{collection_name}/documents")
    res = Req.post(req, json: document)

    handle_response(res)
  end

  def get_document(collection_name, document_id) do
    req = build_request("/collections/#{collection_name}/documents/#{document_id}")
    res = Req.get(req)
    handle_response(res)
  end

  def update_document(collection_name, document) do
    req = build_request("/collections/#{collection_name}/documents/#{document[:id]}")
    res = Req.patch(req, json: document)
    handle_response(res)
  end

  def delete_document(collection_name, document_id) do
    req = build_request("/collections/#{collection_name}/documents/#{document_id}")
    res = Req.delete(req)
    handle_response(res)
  end

  def list_documents!(collection_name, per_page \\ 100, page \\ 1) do
    req = build_request("/collections/#{collection_name}/documents")
    res = Req.get(req, params: [per_page: per_page, page: page])

    handle_response(res)
  end

  ###
  # Documents end
  ###

  def create_search_key() do
    {url, _} = get_env()

    req = build_request("/keys")

    res =
      Req.post(req,
        json: %{
          "description" => "Search-only photos key",
          "actions" => ["documents:search"],
          "collections" => ["photos"]
        }
      )

    data = handle_response(res)

    %{
      url: url,
      api_key: data["value"]
    }
  end

  def handle_response({:ok, %{status: status, body: body}}) do
    case status do
      status when status in 200..209 ->
        body

      400 ->
        Logger.warning("Bad Request: #{inspect(body)}")
        raise "Bad Request"

      401 ->
        raise "Unauthorized"

      404 ->
        nil

      409 ->
        raise "Conflict"

      422 ->
        raise "Unprocessable Entity"

      503 ->
        # TODO: service monitoring, alerting to IM
        raise "Service Unavailable"

      _ ->
        Logger.error("Unhandled status code #{status}: #{inspect(body)}")
        raise "Unknown error: #{status}"
    end
  end

  def handle_response({:error, reason}) do
    Logger.error("Request failed: #{inspect(reason)}")
    raise "Request failed"
  end

  def handle_response!(%{status: status, body: body}) do
    case status do
      status when status in 200..209 ->
        body

      status ->
        Logger.warning("Request failed with status #{status}: #{inspect(body)}")
        raise "Request failed with status #{status}"
    end
  end

  def build_request(path) do
    {url, api_key} = get_env()

    Req.new(
      base_url: url,
      url: path,
      headers: [
        {"Content-Type", "application/json"},
        {"X-TYPESENSE-API-KEY", api_key}
      ]
    )
  end

  defp get_env() do
    url = Application.fetch_env!(:vmemo, :typesense_url) |> validate_url!()

    api_key = Application.fetch_env!(:vmemo, :typesense_api_key)

    {url, api_key}
  end

  defp validate_url!(url) do
    uri = URI.parse(url)

    if uri.scheme in ["http", "https"] and uri.host do
      url
    else
      raise ArgumentError, "Invalid URL: #{url}"
    end
  end
end
