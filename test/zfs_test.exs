defmodule ZFSTest do
  alias Jocker.Engine.Config
  require Config
  import Jocker.Engine.ZFS

  use ExUnit.Case

  test "create clone test" do
    zroot_test = Config.zroot() <> "/create_clone_test"
    create(zroot_test)
    assert 0 == clone(Config.base_layer_snapshot(), zroot_test <> "/zfs_test")
    assert 0 == snapshot(zroot_test <> "/zfs_test@lol")
    assert 0 == destroy(zroot_test <> "/zfs_test@lol")
    assert 0 == destroy(zroot_test <> "/zfs_test")
    assert 0 == destroy(zroot_test)
  end

  test "rename test" do
    zroot_test = Config.zroot() <> "/rename_test"
    zroot_test_new = Config.zroot() <> "/rename_test_newname"
    assert 0 == create(zroot_test)
    assert 0 == rename(zroot_test, zroot_test_new)
    assert 0 == destroy(zroot_test_new)
  end
end
