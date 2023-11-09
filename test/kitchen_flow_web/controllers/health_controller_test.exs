defmodule KitchenFlowWeb.HealthControllerTest do
  use KitchenFlowWeb.ConnCase, async: true

  test "GET /health/live returns 200 ok", %{conn: conn} do
    conn = get(conn, "/health/live")
    assert %{"status" => "ok"} = json_response(conn, 200)
  end

  test "GET /health/ready checks database and broker status", %{conn: conn} do
    conn = get(conn, "/health/ready")
    assert %{"status" => "ready", "checks" => %{"database" => "up"}} = json_response(conn, 200)
  end
end
