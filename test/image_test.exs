defmodule ImageTest do
  use ExUnit.Case
  alias Jocker.Engine.Config
  alias Jocker.Engine.Image
  import Jocker.Engine.Records

  @moduletag :capture_log

  setup_all do
    Application.stop(:jocker)
    start_supervised(Config)
    Jocker.Engine.ZFS.clear_zroot()
  end

  setup do
    start_supervised(Jocker.Engine.MetaData)
    start_supervised(Jocker.Engine.Layer)
    start_supervised({Jocker.Engine.Network, [{"10.13.37.1", "10.13.37.255"}, "jocker0"]})
    start_supervised(Jocker.Engine.ContainerPool)
    on_exit(fn -> stop_and_delete_db() end)
    :ok
  end

  test "create an image with a 'RUN' instruction" do
    file_path = "/root/test_1.txt"

    instructions = [
      from: "base",
      run: ["/bin/sh", "-c", "echo 'lol1' > " <> file_path]
    ]

    {:ok, image(layer_id: layer_id)} = Image.create_image(instructions)
    layer(mountpoint: mountpoint) = Jocker.Engine.MetaData.get_layer(layer_id)
    assert File.read(Path.join(mountpoint, file_path)) == {:ok, "lol1\n"}
  end

  test "create an image with a 'COPY' instruction" do
    instructions = [
      from: "base",
      copy: ["test.txt", "/root/"]
    ]

    context = create_test_context("test_copy_instruction")
    {:ok, image(layer_id: layer_id)} = Image.create_image(instructions, context)
    layer(mountpoint: mountpoint) = Jocker.Engine.MetaData.get_layer(layer_id)
    assert File.read(Path.join(mountpoint, "root/test.txt")) == {:ok, "lol\n"}
  end

  test "create an image using three RUN/COPY instructions" do
    instructions = [
      from: "base",
      copy: ["test.txt", "/root/"],
      run: ["/bin/sh", "-c", "echo 'lol1' > /root/test_1.txt"],
      run: ["/bin/sh", "-c", "echo 'lol2' > /root/test_2.txt"]
    ]

    context = create_test_context("test_image_builder_three_layers")
    {:ok, image(layer_id: layer_id)} = Image.create_image(instructions, context)
    layer(mountpoint: mountpoint) = Jocker.Engine.MetaData.get_layer(layer_id)
    assert File.read(Path.join(mountpoint, "root/test.txt")) == {:ok, "lol\n"}
    assert File.read(Path.join(mountpoint, "root/test_1.txt")) == {:ok, "lol1\n"}
    assert File.read(Path.join(mountpoint, "root/test_2.txt")) == {:ok, "lol2\n"}
  end

  defp create_test_context(name) do
    dataset = Path.join(Config.get(:zroot), name)
    mountpoint = Path.join("/", dataset)
    Jocker.Engine.ZFS.create(dataset)
    {"", 0} = System.cmd("sh", ["-c", "echo 'lol' > #{mountpoint}/test.txt"])
    mountpoint
  end

  defp stop_and_delete_db() do
    # Agent.stop(Jocker.Engine.MetaData)
    File.rm(Config.get(:metadata_db))
  end
end
