defmodule FarmbotExt.MQTT do
  require Logger

  use Tortoise.Handler

  defstruct client_id: "NOT_SET", connection_status: :down, supervisor: nil

  alias FarmbotExt.MQTT.{
    PingHandler,
    RPCHandler,
    Support,
    SyncHandler,
    TerminalHandler,
    TopicSupervisor
  }

  alias __MODULE__, as: State

  def publish(client_id, topic, payload, opts \\ [qos: 0]) do
    # Returns `:ok` or an `{:error, :tuple}`
    Tortoise.publish(client_id, topic, payload, opts)
  end

  def init(args) do
    client_id = Keyword.fetch!(args, :client_id)

    opts = [
      client_id: client_id,
      username: Keyword.fetch!(args, :username)
    ]

    {:ok, supervisor} = TopicSupervisor.start_link(opts)
    {:ok, %State{client_id: client_id, supervisor: supervisor}}
  end

  def handle_message([_, _, "ping", _] = topic, payload, s) do
    Support.forward_message(PingHandler, {topic, payload})
    {:ok, s}
  end

  def handle_message([_, _, "terminal_input"] = topic, payload, s) do
    Support.forward_message(TerminalHandler, {topic, payload})
    {:ok, s}
  end

  def handle_message([_, _, "from_clients"] = topic, payload, s) do
    Support.forward_message(RPCHandler, {topic, payload})
    {:ok, s}
  end

  def handle_message([_, _, "sync" | _] = topic, payload, s) do
    Support.forward_message(SyncHandler, {topic, payload})
    {:ok, s}
  end

  def handle_message(_topic, _payl, state), do: {:ok, state}

  def connection(status, state), do: {:ok, %{state | connection_status: status}}

  def subscription(_stat, _filter, state), do: {:ok, state}
end
