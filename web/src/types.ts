export type Station = "all" | "grill" | "cold" | "bar" | "pastry";
export type Locale = "en" | "es" | "sv";
export type TicketStatus = "queued" | "preparing" | "ready" | "served" | "cancelled";

export interface MenuItem {
  id: string;
  sku: string;
  name: string;
  display_name: string;
  station: Exclude<Station, "all">;
  course: string;
  prep_time_seconds: number;
  price_cents: number;
}

export interface TicketItem {
  id: string;
  menu_item_id: string;
  name: string;
  quantity: number;
  notes?: string;
}

export interface StationTicket {
  id: string;
  order_id: string;
  station: Exclude<Station, "all">;
  status: TicketStatus;
  status_label: string;
  table_number: number;
  items: TicketItem[];
  target_prep_seconds: number;
  sla_breached?: boolean;
  started_at?: string;
  ready_at?: string;
  inserted_at: string;
}
