defmodule KitchenFlow.Events.OutboxWorkerTest do
  use KitchenFlow.DataCase, async: false
  alias KitchenFlow.Events.OutboxWorker

  test "flush_pending/0 completes cleanly when outbox is empty" do
    assert {:ok, 0} = OutboxWorker.flush_pending()
  end
end
