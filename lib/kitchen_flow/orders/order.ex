defmodule KitchenFlow.Orders.Order do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses ~w(open preparing ready completed cancelled)

  schema "orders" do
    field :table_number, :integer
    field :status, :string, default: "open"
    field :notes, :string

    has_many :items, KitchenFlow.Orders.OrderItem
    has_many :station_tickets, KitchenFlow.Orders.StationTicket

    timestamps()
  end

  def changeset(order, attrs) do
    order
    |> cast(attrs, [:table_number, :status, :notes])
    |> validate_required([:table_number])
    |> validate_number(:table_number, greater_than: 0)
    |> validate_inclusion(:status, @statuses)
    |> cast_assoc(:items, with: &KitchenFlow.Orders.OrderItem.changeset/2)
  end
end
