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

An agent is a process that can store state.

## Todo List Example

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
end
```
