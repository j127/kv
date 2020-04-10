defmodule KV.BucketTest do
  # Runs test in parallel with other async tests. Async can only be used
  # if the test doesn't rely on global values (filesystem, database,
  # etc.).
  use ExUnit.Case, async: true

  setup do
    {:ok, bucket} = KV.Bucket.start_link([])
    %{bucket: bucket}
  end

  test "stores values by key" do
    assert KV.Bucket.get(bucket, "milk") == nil

    KV.Bucket.put(bucket, "milk", 3)
    assert KV.Bucket.get(bucket, "milk") == 3
  end
end
