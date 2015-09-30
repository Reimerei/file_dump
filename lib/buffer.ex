defmodule FileDump.Buffer do
  use GenServer

  @timeout 500

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def add_chunk(server, 0 , data) do
    case :erlang.binary_to_term(data) do
      meta = %{file_name: _, chunk_count: _, path: _} ->
        GenServer.cast(server, {:meta, meta})
      invalid ->
        throw("invalid meta packet: #{inspect invalid}")
    end
  end

  def add_chunk(server, seq, data) do
    GenServer.cast(server, {:data, seq, data})
  end

  def get_data(server) do
    GenServer.call(server, :get)
  end

  ##############################################################################
  ## GenServer Callbacks
  ##############################################################################

  def init(:ok) do
    {:ok, %{chunks: %{}}, @timeout}
  end

  def handle_cast({:meta, meta}, state) do
    state = Map.merge(meta, state)
    {:noreply, check_if_complete(state), @timeout}
  end

  def handle_cast({:data, seq, data}, state = %{chunks: chunks}) do
    state = %{state | chunks: Map.put(chunks, seq, data)}
    {:noreply, check_if_complete(state), @timeout}
  end

  def handle_cast(:write_file, state = %{file_name: file_name, path: path, chunks: chunks}) do
    content =
      Enum.sort(chunks)
      |> Enum.map(fn({_, bin}) -> bin end)
      |> Enum.join()

    dir = Path.join(Application.get_env(:file_dump, :base_path), path)
    if (File.exists?(dir)) do
      File.mkdir_p!(dir)
    end
    file_path = Path.join(dir, file_name)
    File.write!(file_path, content)
    {:stop, :normal, state}
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state, @timeout}
  end

  def handle_info(:timeout, state) do
    {:stop, :timeout, state}
  end

  ##############################################################################
  ## Helper
  ##############################################################################

  def check_if_complete(state = %{chunk_count: chunk_count, chunks: chunks}) do
    case length(Map.keys(chunks)) do
      ^chunk_count ->
        GenServer.cast(self(), :write_file)
      _ ->
        :noop
    end
    state
  end

  def check_if_complete(state) do
    state
  end

end
