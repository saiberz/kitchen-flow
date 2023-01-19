defmodule KitchenFlow.Repo.Migrations.CreateStationTickets do
  use Ecto.Migration

  def change do
    create table(:station_tickets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :station, :string, null: false
      add :status, :string, null: false, default: "queued"
      add :table_number, :integer, null: false
      add :items_payload, {:array, :map}, null: false, default: []
      add :target_prep_seconds, :integer, null: false, default: 300
      add :started_at, :utc_datetime
      add :ready_at, :utc_datetime
      add :served_at, :utc_datetime
      add :order_id, references(:orders, on_delete: :delete_all, type: :binary_id), null: false

      timestamps()
    end

    create index(:station_tickets, [:station, :status])
    create index(:station_tickets, [:order_id])
  end
end
