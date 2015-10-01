defmodule FileDump.Test.Client do
  use ExUnit.Case

  @path "client/test"

  setup do
    file1 = File.read!("test/files/file1")
    file2 = File.read!("test/files/file2")
    {:ok, client} = FileDump.Client.start_link(:random.uniform(60000) + 1024)
    {:ok, %{client: client, file1: file1, file2: file2}}
  end

  test "send single file", %{client: client, file1: file1} do
    FileDump.Client.send_file(client, @path, "test1", file1)
    Helper.check_file(Path.join("./store", Path.join(@path, "test1")), file1)
  end

  test "send two files", %{client: client, file1: file1, file2: file2} do
    FileDump.Client.send_file(client, @path, "test2", file1)
    FileDump.Client.send_file(client, @path, "test3", file2)
    Helper.check_file(Path.join("./store", Path.join(@path, "test2")), file1)
    Helper.check_file(Path.join("./store", Path.join(@path, "test3")), file2)
  end
end
