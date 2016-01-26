defmodule FileDump.Client do
  require Log
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, [{:name, __MODULE__} | opts])
  end

  def send_file(path, file_name, content) do
    GenServer.cast(__MODULE__, {:send_file, content, file_name, path})
  end

  def ping() do
    GenServer.call(__MODULE__, :ping)
  end

  ##############################################################################
  ## GenServer callbacks
  ##############################################################################

  def init(:ok) do
    :random.seed(:os.timestamp())
    remote_port = Application.get_env(:file_dump, :port)
    remote_host = Application.get_env(:file_dump, :remote_host)
    local_port  = :random.uniform(65535 - 49152) + 49152
    {:ok, socket} = :gen_udp.open(local_port, [:binary])
    delay = round(1000 / Application.get_env(:file_dump, :send_rate))
    {:ok, %{socket: socket, remote_port: remote_port, remote_host: remote_host, delay: delay}}
  end

  def handle_cast({:send_file, content, file_name, path}, state = %{socket: socket, remote_port: remote_port, remote_host: remote_host, delay: delay}) do
    id = :crypto.rand_bytes(4)
    chunks = chunk_file(content)

    # send meta information
    meta = %{file_name: file_name, path: path, chunk_count: length(chunks)}
    :gen_udp.send(socket, remote_host, remote_port, make_packet(id, 0, meta))

    # send chunks
    chunks
    |> Enum.with_index()
    |> Enum.map(fn({chunk, i}) -> make_packet(id, i + 1, chunk) end )
    |> Enum.each(fn(packet) -> :gen_udp.send(socket, remote_host, remote_port, packet) end)

    # delay to limit rate of files send
    # :timer.sleep(delay)

    # check if we need to delete messages
    # case Process.info(self, :message_queue_len) do
    #   {:message_queue_len, len} when len > @max_queue ->
    #     Log.warn("FileDump: Discarding messages #{len} > #{@max_queue}")
    #     :ok = discard_messages(len - @max_queue)
    #   _ -> :noop
    # end

    {:noreply, state}
  end

  def handle_call(:ping, _, state = %{socket: socket, remote_port: remote_port, remote_host: remote_host}) do
    :gen_udp.send(socket, remote_host, remote_port, "ping")        
    receive do
      {:udp, _, _, _, "pong"} -> {:reply, :ok, state}
      other -> {:reply, {:error, {:unexpected, other}}, state}
    end    
  end

  def chunk_file(<< chunk :: binary-size(1024), rest :: binary >>) do
     [chunk | chunk_file(rest)]
  end

  def chunk_file(<<>>) do
    []
  end

  def chunk_file(<< chunk :: binary >>) do
     [chunk]
  end

  def make_packet(id, seq, payload) when is_number(id) do
    make_packet(<< id :: size(32) >> , seq, payload)
  end

  def make_packet(id, seq, map) when is_map(map) do
    make_packet(id, seq, :erlang.term_to_binary(map))
  end

  def make_packet(id, seq, bin) when is_binary(bin) do
    << id :: binary-size(4), seq :: size(32), bin :: binary >>
  end

  def discard_messages(0) do
    :ok
  end

  def discard_messages(count) do
    receive do
      _ -> discard_messages(count - 1)
    end
  end

end
