defmodule FileDump.Test do
  use ExUnit.Case

  setup do
    {:ok, socket} = :gen_udp.open(4444, [:binary])
    meta = %{file_name: "foo.bin", path: "over/there", chunk_count: 3}
    data = %{file_name: "foo.bin", path: "over/there", chunk_count: 3, chunks: %{ 1 => "bin1", 2 => "bin2", 3 => "bin3"}}
    {:ok, %{socket: socket}}
  end

  def encode(id, seq, data) do
      << id :: size(32), seq :: size(16), data :: binary >>
  end

  test "send complete file", %{socket: socket} do
    Application.put_env(:file_dump, :base_dir, "/tmp/")



  end


end
