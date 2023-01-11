defmodule KitchenFlow.Catalog do
  import Ecto.Query, warn: false
  alias KitchenFlow.Repo
  alias KitchenFlow.Catalog.MenuItem

  def list_menu_items(opts \\ []) do
    MenuItem
    |> maybe_filter_station(opts[:station])
    |> maybe_filter_available(opts[:available])
    |> order_by([m], asc: m.station, asc: m.name)
    |> Repo.all()
  end

  def get_menu_item!(id), do: Repo.get!(MenuItem, id)

  def create_menu_item(attrs \\ %{}) do
    %MenuItem{}
    |> MenuItem.changeset(attrs)
    |> Repo.insert()
  end

  def update_menu_item(%MenuItem{} = item, attrs) do
    item
    |> MenuItem.changeset(attrs)
    |> Repo.update()
  end

  defp maybe_filter_station(query, nil), do: query
  defp maybe_filter_station(query, station), do: where(query, [m], m.station == ^station)

  defp maybe_filter_available(query, nil), do: query
  defp maybe_filter_available(query, available), do: where(query, [m], m.available == ^available)
end
