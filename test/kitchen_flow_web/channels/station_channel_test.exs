defmodule KitchenFlowWeb.StationChannelTest do
  use KitchenFlowWeb.ChannelCase

  alias KitchenFlowWeb.StationChannel
  alias KitchenFlowWeb.UserSocket

  test "joins station:grill topic successfully" do
    {:ok, _, socket} =
      KitchenFlowWeb.UserSocket
      |> socket("user_id", %{})
      |> subscribe_and_join(StationChannel, "station:grill")

    assert socket.assigns.station == "grill"
  end

  test "rejects joining invalid station topic" do
    assert {:error, %{reason: "unknown_station"}} =
      KitchenFlowWeb.UserSocket
      |> socket("user_id", %{})
      |> subscribe_and_join(StationChannel, "station:unknown")
  end
end
