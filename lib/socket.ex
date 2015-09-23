defmodule FileDump.Socket do
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  ##############################################################################
  ## Genserver Callbacks
  ##############################################################################

  def init(:ok) do
    # Process.flag(:trap_exit, true)
    {:ok, socket} = :gen_udp.open(3333, [:binary])
    {:ok, %{buffers: %{}, socket: socket}}
  end

  def handle_info({:udp, _, _, _, << id :: size(32), seq :: size(16), data :: binary >>}, state = %{buffers: buffers}) do
    case Map.get(buffers, id) do
      nil ->
        {:ok, pid} = FileDump.Buffer.start_link(id)
        FileDump.Buffer.add_chunk(pid, seq, data)
        {:noreply, %{state | buffers: Map.put(buffers, id, pid)}}
      pid ->
        FileDump.Buffer.add_chunk(pid, seq, data)
        {:noreply, state}
    end
  end

  def handle_info({:EXIT, _pid, {_, id}}, state = %{buffers: buffers}) do
    {:noreply, %{state | buffers: Map.delete(buffers, id)}}
  end

  def handle_info(msg, state) do
    Logger.error("Unhandled message: #{inspect msg}")
    {:noreply, state}
  end


end
