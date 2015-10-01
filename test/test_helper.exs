ExUnit.start()

defmodule Helper do
  use ExUnit.Case
  @wait 100

  def check_file(file_name, compare_to) do
    check_file(file_name, compare_to, 1000)
  end

  def check_file(_file_name, _compare_to, 0) do
    assert(false, "max wait exceeded")
  end

  def check_file(file_name, compare_to, reps) do
    if (File.exists?(file_name)) do
      assert byte_size(File.read!(file_name)) == byte_size(compare_to)
      File.rm(file_name)
    else
      :timer.sleep(@wait)
      check_file(file_name, compare_to, reps - 1)
    end
  end
end
