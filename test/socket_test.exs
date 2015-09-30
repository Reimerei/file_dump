defmodule FileDump.Test.Socket do
  use ExUnit.Case

  @path "some/path"

  setup do
    :random.seed(:os.timestamp())

    file1 = File.read!("test/files/file1")
    file2 = File.read!("test/files/file2")

    {:ok, socket} = FileDump.Socket.start_link(:random.uniform(60000) + 1024)

    {:ok, %{socket: socket, file1: file1, file2: file2}}
  end

  test "single file: packets in order", %{socket: socket, file1: file1} do
    create_packets(:random.uniform(1000000), file1, %{file_name: "test1", path: @path})
    |>  Enum.each(fn (packet) -> send(socket, packet) end)
    :timer.sleep(100)
    check_file("test1", file1)
  end

  test "single file: packets shuffled", %{socket: socket, file1: file1} do
    create_packets(:random.uniform(1000000), file1, %{file_name: "test2", path: @path})
    |> Enum.shuffle()
    |> Enum.each(fn (packet) -> send(socket, packet) end)
    :timer.sleep(100)
    check_file("test2", file1)
  end

  test "two files: packets shuffled", %{socket: socket, file1: file1, file2: file2} do
    p1 = create_packets(:random.uniform(1000000), file1, %{file_name: "test3", path: @path})
    p2 = create_packets(:random.uniform(1000000), file2, %{file_name: "test4", path: @path})
    p1 ++ p2
    |> Enum.shuffle()
    |> Enum.each(fn (packet) -> send(socket, packet) end)
    :timer.sleep(100)
    check_file("test3", file1)
    check_file("test4", file2)
  end

  test "two files: with some packets dropped", %{socket: socket, file1: file1, file2: file2} do
    p1 = create_packets(:random.uniform(1000000), file1, %{file_name: "test5", path: @path})
    p2 =
      create_packets(:random.uniform(1000000), file2, %{file_name: "test6", path: @path})
      |> Enum.drop(2)
    p1 ++ p2
    |> Enum.shuffle()
    |> Enum.each(fn (packet) -> send(socket, packet) end)
    :timer.sleep(100)
    check_file("test5", file1)
    assert !File.exists?(Path.join("./store", Path.join(@path, "test6")))
  end

  def check_file(file_name, compare_to) do
    path = Path.join("./store", Path.join(@path, file_name))
    assert File.read!(path) == compare_to
    File.rm(path)
  end

  def create_packets(id, file, meta) do
    chunks =
      file
      |> FileDump.Utils.chunk_file()
      |> Enum.with_index()
      |> Enum.map(fn({chunk, i}) -> {:udp, :a, :a, :a, << id :: size(32), i + 1 :: size(32), chunk :: binary >>} end)
    meta = {:udp, :a, :a, :a, << id :: size(32), 0 :: size(32), :erlang.term_to_binary(Map.put(meta, :chunk_count, length(chunks))) :: binary >>}
    [meta | chunks]
  end


end
