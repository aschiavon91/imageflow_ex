defmodule Imageflow.GraphRunner do
  @moduledoc """
  Execute the graph and generates the output
  """

  alias Imageflow.{Graph, Native}

  def run(%Graph{} = graph) do
    with {:ok, job} <- Native.create(),
         {:ok, job} <- process_tasks(job, graph) do
      job
      |> save_outputs(graph.outputs)
      |> handle_result(job)
    end
  end

  defp process_tasks(job, graph) do
    with :ok <- add_inputs(job, graph.inputs),
         :ok <- add_outputs(job, graph.outputs),
         :ok <- send_task(job, graph) do
      {:ok, job}
    end
  end

  defp handle_result(res, job) do
    case Native.destroy(job) do
      {:ok, :job_destroyed} -> res
      err -> err
    end
  end

  defp add_inputs(job, inputs) do
    inputs
    |> Enum.reduce_while(:ok, fn
      {id, value}, :ok ->
        case value do
          {:file, path} ->
            Native.add_input_file(job, id, path)

          {:buffer, bytes} ->
            Native.add_input_buffer(job, id, bytes)
        end
        |> case do
          {:ok, _} -> {:cont, :ok}
          {:error, _} = error -> {:halt, error}
        end
    end)
  end

  defp add_outputs(job, inputs) do
    inputs
    |> Enum.reduce_while(:ok, fn
      {id, _}, :ok ->
        case Native.add_output_buffer(job, id) do
          {:ok, _} -> {:cont, :ok}
          {:error, _} = error -> {:halt, error}
        end
    end)
  end

  defp save_outputs(job, outputs) do
    outputs
    |> Enum.reduce_while(:ok, fn
      {id, value}, :ok -> do_save_output(job, id, value)
      {id, value}, {:ok, _} -> do_save_output(job, id, value)
    end)
  end

  defp do_save_output(job, id, value) do
    case value do
      {:file, path} -> Native.save_output_to_file(job, id, path)
      :buffer -> Native.get_output_buffer(job, id)
    end
    |> case do
      :ok -> {:cont, :ok}
      {:ok, data} -> {:cont, {:ok, data}}
      {:error, _} = error -> {:halt, error}
    end
  end

  defp send_task(job, graph) do
    with {:ok, _response} <- Native.message(job, "v1/execute", graph) do
      :ok
    end
  end
end
