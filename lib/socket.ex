defmodule FileDump.Socket do
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  ##############################################################################
  ## GenServer Callbacks
  ##############################################################################

  def init(:ok) do
    Process.flag(:trap_exit, true)
    port = Application.get_env(:file_dump, :listen_port)
    Logger.info("Listening on port #{port}")
    {:ok, socket} = :gen_udp.open(port, [:binary])
    {:ok, %{buffers: %{}, socket: socket}}
  end

  def handle_info({:udp, _, _, _, << id :: size(32), seq :: size(16), data :: binary >>}, state = %{buffers: buffers}) do
    case Map.get(buffers, id) do
      nil ->
        {:ok, pid} = FileDump.Buffer.start_link()
        FileDump.Buffer.add_chunk(pid, seq, data)
        {:noreply, %{state | buffers: Map.put(buffers, id, pid)}}
      pid ->
        FileDump.Buffer.add_chunk(pid, seq, data)
        {:noreply, state}
    end
  end

  def handle_info({:EXIT, pid, _reason}, state = %{buffers: buffers}) do
    {id, _} = buffers |> Enum.find(fn({_,p}) -> p == pid end)
    {:noreply, %{state | buffers: Map.delete(buffers, id)}}
    # {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.error("Unhandled message: #{inspect msg}")
    {:noreply, state}
  end
end
