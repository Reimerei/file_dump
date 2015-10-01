defmodule FileDump.Client do
  require Logger
  use GenServer

  def start_link(local_port \\ nil,opts \\ []) do
    GenServer.start_link(__MODULE__, local_port, opts)
  end

  def send_file(server, path, file_name, content) do
    GenServer.cast(server, {:send_file, content, file_name, path})
  end

  ##############################################################################
  ## GenServer callbacks
  ##############################################################################

  def init(nil) do
    init(Application.get_env(:file_dump, :port))
  end

  def init(local_port) do
    :random.seed(:os.timestamp())
    remote_port = Application.get_env(:file_dump, :port)
    remote_host = Application.get_env(:file_dump, :remote_host)
    {:ok, socket} = :gen_udp.open(local_port, [:binary])
    {:ok, %{socket: socket, port: remote_port, remote_host: remote_host}}
  end

  def handle_cast({:send_file, content, file_name, path}, state = %{socket: socket, port: port, remote_host: remote_host}) do
    id = :crypto.rand_bytes(4)
    chunks = chunk_file(content)

    # send meta information
    meta = %{file_name: file_name, path: path, chunk_count: length(chunks)}
    :gen_udp.send(socket, remote_host, port, make_packet(id, 0, meta))

    # send chunks
    chunks
    |> Enum.with_index()
    |> Enum.map(fn({chunk, i}) -> make_packet(id, i + 1, chunk) end )
    |> Enum.each(fn(packet) -> :gen_udp.send(socket, remote_host, port, packet) end)

    {:noreply, state}
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

end
