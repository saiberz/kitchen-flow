defmodule KitchenFlowWeb.FallbackController do
  use KitchenFlowWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(KitchenFlowWeb.ChangesetView)
    |> render("error.json", changeset: changeset)
  end

  def call(conn, {:error, :invalid_transition}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: %{status: ["invalid status transition"]}})
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(KitchenFlowWeb.ErrorView)
    |> render(:"404")
  end
end
