defmodule KitchenFlowWeb.OrderControllerTest do
  use KitchenFlowWeb.ConnCase, async: true

  alias KitchenFlow.Catalog

  setup %{conn: conn} do
    {:ok, item} =
      Catalog.create_menu_item(%{
        sku: "COLD-01",
        name: "Caesar Salad",
        station: "cold",
        course: "starter",
        prep_time_seconds: 240,
        price_cents: 1400
      })

    {:ok, conn: put_req_header(conn, "accept", "application/json"), item: item}
  end

  test "POST /api/orders creates order and returns station tickets", %{conn: conn, item: item} do
    payload = %{
      "order" => %{
        "table_number" => 7,
        "items" => [%{"menu_item_id" => item.id, "quantity" => 1}]
      }
    }

    conn = post(conn, Routes.order_path(conn, :create), payload)
    assert %{"id" => _id, "table_number" => 7, "station_tickets" => [ticket]} = json_response(conn, 201)["data"]
    assert ticket["station"] == "cold"
    assert ticket["status"] == "queued"
  end

  test "PATCH /api/tickets/:id/status returns 422 on invalid state jump", %{conn: conn, item: item} do
    create_conn =
      post(conn, Routes.order_path(conn, :create), %{
        "order" => %{"table_number" => 3, "items" => [%{"menu_item_id" => item.id, "quantity" => 1}]}
      })

    [%{"id" => ticket_id}] = json_response(create_conn, 201)["data"]["station_tickets"]

    patch_conn = patch(conn, Routes.station_ticket_path(conn, :update_status, ticket_id), %{"status" => "served"})
    assert %{"errors" => %{"status" => ["invalid status transition"]}} = json_response(patch_conn, 422)
  end
end
