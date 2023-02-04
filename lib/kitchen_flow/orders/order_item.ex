defmodule KitchenFlow.Orders.OrderItem do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "order_items" do
    field :quantity, :integer, default: 1
    field :notes, :string
    field :station, :string
    field :item_name, :string
    field :prep_time_seconds, :integer, default: 300

    belongs_to :order, KitchenFlow.Orders.Order
    belongs_to :menu_item, KitchenFlow.Catalog.MenuItem

    timestamps()
  end

  def changeset(order_item, attrs) do
    order_item
    |> cast(attrs, [:menu_item_id, :quantity, :notes, :station, :item_name, :prep_time_seconds])
    |> validate_required([:menu_item_id, :quantity, :station, :item_name])
    |> validate_number(:quantity, greater_than: 0)
  end
end
