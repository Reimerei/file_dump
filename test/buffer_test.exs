defmodule FileDump.Test.Buffer do
  use ExUnit.Case
  import Mock

  setup do
    {:ok, buffer} = FileDump.Buffer.start_link
    data = %{file_name: "foo.bin", path: "over/there", chunk_count: 3, chunks: %{ 1 => "bin1", 2 => "bin2"}}
    {_, meta} = Map.pop(data, :chunks)
    {:ok, %{buffer: buffer, data: data, meta: meta}}
  end

  test "return error for invalid metas", %{buffer: buffer} do
    assert "invalid meta packet: %{foo: 123}" = catch_throw(FileDump.Buffer.add_chunk(buffer, 0, :erlang.term_to_binary(%{foo: 123})))
  end

  test "receive chunks in order", %{buffer: buffer, data: data, meta: meta} do
     FileDump.Buffer.add_chunk(buffer, 0, :erlang.term_to_binary(meta))
     FileDump.Buffer.add_chunk(buffer, 1, data.chunks[1])
     FileDump.Buffer.add_chunk(buffer, 2, data.chunks[2])
     assert data == FileDump.Buffer.get_data(buffer)
  end

  test "receive chunks out of order", %{buffer: buffer, data: data, meta: meta} do
     FileDump.Buffer.add_chunk(buffer, 2, data.chunks[2])
     FileDump.Buffer.add_chunk(buffer, 0, :erlang.term_to_binary(meta))
     FileDump.Buffer.add_chunk(buffer, 1, data.chunks[1])
     assert data == FileDump.Buffer.get_data(buffer)
  end

  test "timeout when a packet does not arrive", %{buffer: buffer, data: data} do
    Process.flag(:trap_exit, true)
    FileDump.Buffer.add_chunk(buffer, 1, data.chunks[1])
    :timer.sleep(550)
    assert_receive({:EXIT, _pid, :timeout})
  end

  def mock_file_write("./over/there/foo.bin", "bin1bin2bin3"), do: :ok

  test "write file when all data has arrived", %{buffer: buffer, data: data, meta: meta} do
    with_mock File, [:passthrough], [write!: &mock_file_write/2] do
      Application.put_env(:file_dump, :base_path, "./")
      Process.flag(:trap_exit, true)
      FileDump.Buffer.add_chunk(buffer, 0, :erlang.term_to_binary(meta))
      FileDump.Buffer.add_chunk(buffer, 1, data.chunks[1])
      FileDump.Buffer.add_chunk(buffer, 2, data.chunks[2])
      FileDump.Buffer.add_chunk(buffer, 3, "bin3")
      assert_receive({:EXIT, _pid, :normal})
    end
  end

end
