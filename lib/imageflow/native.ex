defmodule Imageflow.Native do
  @moduledoc """
  Low-level FFI bindings to `imageflow`

  Example usage:

      alias Imageflow.Native

      # create a job
      {:ok, job} = Native.create()

      # add an input file, with id `0`
      :ok = Native.add_input_file(job, 0, "input.jpg")

      # you could also add input buffers directly from memory
      :ok = Native.add_input_buffer(job, 1, <<0x89, 0x50, 0x4E, 0x47, 0x0D, ... >>)

      # call `get_image_info` on buffer with id 0
      {:ok, resp} = Native.message("v0.1/get_image_info", %{io_id: 0})
  """

  alias Imageflow.NIF

  @type t :: %__MODULE__{}
  @type native_ret_t :: {:ok, term()} | {:error, atom()}

  defstruct id: nil

  @spec create :: native_ret_t
  def create do
    case NIF.job_create() do
      {:ok, id} -> {:ok, %__MODULE__{id: id}}
      err -> err
    end
  end

  @spec create! :: term | no_return()
  def create! do
    case create() do
      {:ok, job} -> job
      err -> raise RuntimeError, err
    end
  end

  @spec destroy(t()) :: native_ret_t
  def destroy(%__MODULE__{id: id}), do: NIF.job_destroy(id)

  @spec add_input_buffer(t, number, binary) :: native_ret_t
  def add_input_buffer(%__MODULE__{id: id}, io_id, bytes) do
    NIF.job_add_input_buffer(id, io_id, bytes)
  end

  @spec add_input_file(t, number, binary) :: native_ret_t
  def add_input_file(%__MODULE__{id: id}, io_id, path) do
    NIF.job_add_input_file(id, io_id, path)
  end

  @spec add_output_buffer(t, number) :: native_ret_t
  def add_output_buffer(%__MODULE__{id: id}, io_id) do
    NIF.job_add_output_buffer(id, io_id)
  end

  @spec save_output_to_file(t, number, binary) :: native_ret_t
  def save_output_to_file(%__MODULE__{id: id}, io_id, path) do
    NIF.job_save_output_to_file(id, io_id, path)
  end

  @spec get_output_buffer(t, number) :: {:ok, binary} | {:error, binary}
  def get_output_buffer(%__MODULE__{id: id} = _job, io_id) do
    NIF.job_get_output_buffer(id, io_id)
  end

  @spec message(t, binary, binary) :: {:ok, any} | {:error, binary}
  def message(%__MODULE__{id: id}, method, message) do
    with {:ok, resp} <- NIF.job_message(id, method, Jason.encode!(message)) do
      {:ok, Jason.decode!(resp)}
    end
  end
end
