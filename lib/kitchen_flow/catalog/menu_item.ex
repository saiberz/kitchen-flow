defmodule KitchenFlow.Catalog.MenuItem do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @stations ~w(grill cold bar pastry)
  @courses ~w(drinks starter main dessert)

  schema "menu_items" do
    field :sku, :string
    field :name, :string
    field :station, :string
    field :course, :string, default: "main"
    field :prep_time_seconds, :integer, default: 300
    field :price_cents, :integer
    field :available, :boolean, default: true

    timestamps()
  end

  def stations, do: @stations

  def changeset(menu_item, attrs) do
    menu_item
    |> cast(attrs, [:sku, :name, :station, :course, :prep_time_seconds, :price_cents, :available])
    |> validate_required([:sku, :name, :station, :prep_time_seconds, :price_cents])
    |> validate_inclusion(:station, @stations)
    |> validate_inclusion(:course, @courses)
    |> validate_number(:prep_time_seconds, greater_than: 0)
    |> validate_number(:price_cents, greater_than_or_equal_to: 0)
    |> unique_constraint(:sku)
  end
end
