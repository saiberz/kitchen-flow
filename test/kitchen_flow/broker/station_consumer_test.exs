defmodule KitchenFlow.Broker.StationConsumerTest do
  use ExUnit.Case, async: false

  alias KitchenFlow.Broker.StationConsumer

  test "process_payload/1 deduplicates repeated deliveries with same event_id" do
    event_id = Ecto.UUID.generate()

    payload =
      Jason.encode!(%{
        "event_id" => event_id,
        "ticket_id" => Ecto.UUID.generate(),
        "station" => "grill",
        "table_number" => 4
      })

    assert {:ok, :processed, _} = StationConsumer.process_payload(payload)
    assert {:ok, :duplicate, _} = StationConsumer.process_payload(payload)
  end

  test "process_payload/1 rejects malformed payloads for dead-letter routing" do
    assert {:error, :invalid_json} = StationConsumer.process_payload("{broken")
    assert {:error, :missing_required_fields} = StationConsumer.process_payload(~s({"foo": "bar"}))
  end
end
