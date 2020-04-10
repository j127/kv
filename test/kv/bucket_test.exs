defmodule KV.BucketTest do
  # Runs test in parallel with other async tests. Async can only be used
  # if the test doesn't rely on global values (filesystem, database,
  # etc.).
  use ExUnit.Case, async: true

  setup do
    {:ok, bucket} = KV.Bucket.start_link([])
    %{bucket: bucket}
  end

  # pattern match the test context out of the setup info
  test "stores values by key", %{bucket: bucket} do
    assert KV.Bucket.get(bucket, "milk") == nil

    KV.Bucket.put(bucket, "milk", 3)
    assert KV.Bucket.get(bucket, "milk") == 3
  end

  test "deletes a value by key, if it exists", %{bucket: bucket} do
    # bucket is empty
    assert KV.Bucket.get(bucket, "mochi") == nil
    assert KV.Bucket.get(bucket, "daikon") == nil

    # put stuff in bucket
    KV.Bucket.put(bucket, "mochi", 2)
    KV.Bucket.put(bucket, "daikon", 1)

    # stuff should be in bucket
    assert KV.Bucket.get(bucket, "mochi") == 2
    assert KV.Bucket.get(bucket, "daikon") == 1

    # delete from bucket
    deleted_val = KV.Bucket.delete(bucket, "mochi")
    assert deleted_val == 2

    # make sure it was deleted
    assert KV.Bucket.get(bucket, "mochi") == nil
  end
end
