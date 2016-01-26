defmodule FileDump.Socket do
  use GenServer
  require Log

  def start_link(port \\ nil, opts \\ []) do
    GenServer.start_link(__MODULE__, port, opts)
  end

  ##############################################################################
  ## GenServer Callbacks
  ##############################################################################

  def init(nil) do
    init(Application.get_env(:file_dump, :port))
  end

  def init(port) do
    Process.flag(:trap_exit, true)
    Log.info("Listening on port #{port}")
    {:ok, socket} = :gen_udp.open(port, [:binary])
    {:ok, %{buffers: %{}, socket: socket}}
  end

  def handle_info({:udp, _, remote_host, remote_port, "ping"}, state = %{socket: socket}) do
    :gen_udp.send(socket, remote_host, remote_port, "pong")
    {:noreply, state}
  end

  def handle_info({:udp, _, _, _, << id :: integer-size(32), seq :: integer-size(32), data :: binary >>}, state = %{buffers: buffers}) do
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
  end

  def handle_info(msg, state) do
    Log.error("Unhandled message: #{inspect msg}")
    {:noreply, state}
  end
end
