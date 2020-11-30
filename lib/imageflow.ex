defmodule Imageflow do
  alias Imageflow.{Native, Job}

  def get_long_version_string(), do: Native.get_long_version_string()

  @img <<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44,
         0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F,
         0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00,
         0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
         0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82>>

  def test do
    with {:ok, j} <- Job.create(),
         :ok <- Job.add_input(j, 0, @img),
         r <- Job.message(j, "v0.1/get_image_info", %{io_id: 0}),
         :ok <- Job.destroy(j) do
      r
    end
  end
end
