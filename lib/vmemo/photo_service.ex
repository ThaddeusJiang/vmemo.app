defmodule Vmemo.PhotoService do
  alias SmallSdk.FileSystem

  def cp_file(src, user_id, filename) do
    dest = FileSystem.cp!(src, gen_dest(user_id, filename))
    {:ok, dest}
  end

  defp gen_dest(user_id, filename) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix() |> Integer.to_string()

    Path.join([Integer.to_string(user_id), "photos", timestamp <> "_" <> filename])
  end

  def create_ts_photo(
        %{
          image: image,
          note: note,
          url: url,
          inserted_by: inserted_by
        } = _photo
      ) do
    inserted_at = DateTime.utc_now() |> DateTime.to_unix()

    Vmemo.PhotoService.TsPhoto.create_photo(%{
      image: image,
      note: note,
      url: url,
      inserted_at: inserted_at,
      inserted_by: inserted_by
    })
  end
end
