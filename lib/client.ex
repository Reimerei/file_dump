defmodule FileDump.Client do
  require Logger
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def send_file(server, content, file_name, path) do
    GenServer.cast(server, {:send_file, content, file_name, path})
  end

  ##############################################################################
  ## GenServer callbacks
  ##############################################################################

  def init(:ok) do
    port = Application.get_env(:file_dump, :port)
    remote_host = Application.get_env(:file_dump, :remote_host)
    {:ok, socket} = :gen_udp.open(port, [:binary])
    {:ok, %{socket: socket, port: port, remote_host: remote_host}}
  end

  def handle_cast({:send_file, content, file_name, path}, state) do

  end



end
