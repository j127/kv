# Elixir OTP Notes

Notes on OTP in Elixir. They come from the docs, supplemental reading, and experimentation.

## State in Elixir

There are two main ways to share state in Elixir:

1. Store the state in processes and use message passing. This can be done with built-in features like:
    - `Agent` (simple state storage)
    - `GenServer` (generic servers)
    - `Task` (asynchronous computed tasks)
2. Use Erlang Term Storage (ETS), an in-memory key-value store

## `Agent`

An agent is a process that can store state. It has a client-server structure (see below).

### Todo List Example

Start an agent with a linked list:

```elixir
{:ok, todos} = Agent.start_link(fn -> [] end)
#=> {:ok, #PID<0.194.0>}
```

The name `todos` will refer to the PID of the Erlang process that holds the agent. You will probably see a different PID number each time you create an agent.

Update the agent's state:

```elixir
Agent.update(todos, fn list -> ["get some exercise" | list] end)
Agent.update(todos, fn list -> ["read a book" | list] end)
```

Read from the agent:

```elixir
Agent.get(todos, fn list -> list end)
#=> ["read a book", "get some exercise"]
```

## Character Data Example

Start an agent with a map:

```elixir
{:ok, agent} = Agent.start_link(fn -> %{} end)
```

Add some data:

```elixir
Agent.update(agent, &Map.put(&1, "name", "Bilbo"))
Agent.update(agent, &Map.put(&1, "age", 111))
Agent.update(agent, &Map.put(&1, "equipment", ["mithril shirt", "ring"]))
```

Get the data:

```elixir
# get a single value
Agent.get(agent, &Map.get(&1, "name"))
#=> "Bilbo"

# get all the state
Agent.get(agent, fn m -> m end)
#=> %{"age" => 111, "equipment" => ["mithril shirt", "ring"], "name" => "Bilbo"}
```

### Implementation

The [docs](https://elixir-lang.org/getting-started/mix-otp/agent.html) show an example of implementing a simple key-value store using an agent in a file named `lib/kv/bucket.ex`:

```elixir
defmodule KV.Bucket do
  use Agent

  @doc """
  Start a bucket
  """
  def start_link(_opts) do
    Agent.start_link(fn -> %{} end)
  end

  @doc """
  Get a value from the bucket by key
  """
  def get(bucket, key) do
    Agent.get(bucket, &Map.get(&1, key))
  end

  @doc """
  Put a key-value pair in the bucket
  """
  def put(bucket, key, value) do
    Agent.update(bucket, &Map.put(&1, key, value))
  end

  @doc """
  Delete `key` from `bucket`

  Return the current value of `key`, if it exists

  The `&Map.pop/2` function there can be replaced with any function. The
  function runs on the "server" part of the Agent, so it's blocking (see
  below).
  """
  def delete(bucket, key) do
    Agent.get_and_update(bucket, &Map.pop(&1, key))
  end
end
```

Here is the corresponding test in `test/kv/bucket_test.exs`:

```elixir
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
```

Here is an example of the client server structure from the docs. The function in the second argument of `Agent.get_and_update/2` takes place on the Agent "server".

```elixir
def delete(bucket, key) do
  # If you sleep here, it puts the client to sleep
  Process.sleep(1000)

  Agent.get_and_update(bucket, fn dict ->
    # If you sleep here, it puts the server to sleep (blocking in that process)
    Process.sleep(1000)
    Map.pop(dict, key)
  end)
end
```

You can create Agent processes with atoms (`Agent.start_link(fn -> %{} end, name: :todos)`), but atoms are never garbage collected, so it isn't a good idea. Users could dynmaically inject atoms into the system, using up all the memory.
