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
end
