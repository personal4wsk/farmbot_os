defmodule FarmbotExt.MQTTTest do
  use ExUnit.Case
  use Mimic
  alias FarmbotExt.MQTT
  alias FarmbotExt.MQTT.Support

  test "publish/4" do
    client_id = "client_id_123"
    topic = "foo/bar/baz"
    payload = "{}"
    opts = [qos: 3]

    expect(Tortoise, :publish, 1, fn a, b, c, d ->
      assert a == client_id
      assert b == topic
      assert c == payload
      assert d == opts
    end)

    MQTT.publish(client_id, topic, payload, opts)
  end

  test "init" do
    client_id = "my_client_id"
    username = "my_username"
    fake_opts = [client_id: client_id, username: username]
    {:ok, pid} = GenServer.start_link(MQTT, fake_opts)
    assert is_pid(pid)
    state = :sys.get_state(pid)
    assert state.client_id == client_id
    assert state.connection_status == :down
    assert is_pid(state.supervisor)
    Process.exit(pid, :normal)
  end

  test "handle_message/3" do
    fake_state = %MQTT{}
    fake_payload = "{}"

    fake_topics = [
      fake_ping = ["", "", "ping", ""],
      fake_terminal_input = ["", "", "terminal_input"],
      fake_from_clients = ["", "", "from_clients"],
      fake_sync = ["", "", "sync", ""],
      []
    ]

    expect(Support, :forward_message, 4, fn
      FarmbotExt.MQTT.PingHandler, {topic, payload} ->
        assert topic == fake_ping
        assert payload == fake_payload

      FarmbotExt.MQTT.TerminalHandler, {topic, payload} ->
        assert topic == fake_terminal_input
        assert payload == fake_payload

      FarmbotExt.MQTT.RPCHandler, {topic, payload} ->
        assert topic == fake_from_clients
        assert payload == fake_payload

      FarmbotExt.MQTT.SyncHandler, {topic, payload} ->
        assert topic == fake_sync
        assert payload == fake_payload
    end)

    Enum.map(fake_topics, fn topic ->
      resp = MQTT.handle_message(topic, fake_payload, fake_state)
      assert resp == {:ok, fake_state}
    end)
  end
end
