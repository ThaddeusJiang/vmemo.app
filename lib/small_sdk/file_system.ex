defmodule SmallSdk.FileSystem do
  @moduledoc """
  A module to interact with the file system.

  naming reference: Expo.dev FileSystem
  """

  @v1 "storage/v1"
  def cp!(src, dest) do
    dest = Path.join([@v1, dest])

    dest_dir = Path.dirname(dest)

    File.mkdir_p!(dest_dir)

    File.cp!(src, dest)
  end
end
