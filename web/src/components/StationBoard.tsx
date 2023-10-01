import React from "react";
import { Locale, StationTicket, TicketStatus } from "../types";
import { UI_LABELS } from "../i18n";

interface Props {
  tickets: StationTicket[];
  locale: Locale;
  itemNamesById?: Record<string, string>;
  groupByOrder?: boolean;
  onTransition: (ticketId: string, nextStatus: TicketStatus) => void;
}

function formatArrivalTime(iso: string): string {
  if (!iso) return "";
  const normalized = iso.endsWith("Z") ? iso : `${iso}Z`;
  const d = new Date(normalized);
  if (Number.isNaN(d.getTime())) return "";
  return d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", second: "2-digit" });
}

function formatDuration(sec: number): string {
  const m = Math.floor(sec / 60);
  const s = sec % 60;
  return s > 0 ? `${m}m ${s}s` : `${m}m`;
}

export const StationBoard: React.FC<Props> = ({
  tickets,
  locale,
  itemNamesById = {},
  groupByOrder = false,
  onTransition
}) => {
  const t = UI_LABELS[locale];
  const visible = tickets
    .filter((tk) => tk.status !== "served" && tk.status !== "cancelled")
    .sort((a, b) => a.inserted_at.localeCompare(b.inserted_at));

  if (visible.length === 0) {
    return <p className="empty-state">{t.empty}</p>;
  }

  if (groupByOrder) {
    const grouped = new Map<string, StationTicket[]>();
    for (const tk of visible) {
      const list = grouped.get(tk.order_id) || [];
      list.push(tk);
      grouped.set(tk.order_id, list);
    }

    return (
      <div className="ticket-grid">
        {Array.from(grouped.entries()).map(([orderId, orderTickets], idx) => {
          const tableNumber = orderTickets[0].table_number;
          const arrivedAt = formatArrivalTime(orderTickets[0].inserted_at);
          const readyCount = orderTickets.filter((tk) => tk.status === "ready").length;
          const allReady = readyCount === orderTickets.length;

          return (
            <div
              key={orderId}
              className={`ticket-card ${allReady ? "status-ready" : "status-preparing"}`}
            >
              <header className="ticket-header">
                <div>
                  <span className="seq-badge">#{idx + 1}</span>
                  <strong>{t.table} #{tableNumber}</strong>
                  <span className="order-ref">
                    {t.order} #{orderId.slice(0, 4).toUpperCase()}
                  </span>
                </div>
                <span className={`station-badge ${allReady ? "badge-ready" : ""}`}>
                  {readyCount}/{orderTickets.length} {t.readyCount}
                </span>
              </header>
              {arrivedAt && <div className="ticket-meta">In: {arrivedAt}</div>}
              <div className="order-stations-list">
                {orderTickets.map((ticket) => (
                  <div key={ticket.id} className="order-station-block">
                    <div className="order-station-header">
                      <span className="station-badge">{t[ticket.station] || ticket.station}</span>
                      <span className={`status-pill status-pill-${ticket.status}`}>
                        {t[ticket.status] || ticket.status_label || ticket.status}
                      </span>
                    </div>
                    <ul className="ticket-items">
                      {ticket.items.map((item) => (
                        <li key={item.id}>
                          <span className="qty">{item.quantity}x</span>{" "}
                          {itemNamesById[item.menu_item_id] || item.name}
                          {item.notes && <em className="item-notes"> ({item.notes})</em>}
                        </li>
                      ))}
                    </ul>
                    {ticket.status === "ready" && (
                      <div className="ticket-actions">
                        <button onClick={() => onTransition(ticket.id, "served")}>
                          {t.markServed}
                        </button>
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </div>
          );
        })}
      </div>
    );
  }

  return (
    <div className="ticket-grid">
      {visible.map((ticket, idx) => (
        <div
          key={ticket.id}
          className={`ticket-card status-${ticket.status}`}
        >
          <header className="ticket-header">
            <div>
              <span className="seq-badge">#{idx + 1}</span>
              <strong>{t.table} #{ticket.table_number}</strong>
              <span className="order-ref">
                {t.order} #{ticket.order_id.slice(0, 4).toUpperCase()}
              </span>
            </div>
            <span className="station-badge">{t[ticket.station] || ticket.station}</span>
          </header>
          <div className="ticket-meta">
            <span>In: {formatArrivalTime(ticket.inserted_at)}</span>
            <span>Prep: {formatDuration(ticket.target_prep_seconds)}</span>
          </div>
          <ul className="ticket-items">
            {ticket.items.map((item) => (
              <li key={item.id}>
                <span className="qty">{item.quantity}x</span> {itemNamesById[item.menu_item_id] || item.name}
                {item.notes && <em className="item-notes"> ({item.notes})</em>}
              </li>
            ))}
          </ul>
          <footer className="ticket-actions">
            {ticket.status === "queued" && (
              <button onClick={() => onTransition(ticket.id, "preparing")}>{t.startPrep}</button>
            )}
            {ticket.status === "preparing" && (
              <button onClick={() => onTransition(ticket.id, "ready")}>{t.markReady}</button>
            )}
            {ticket.status === "ready" && (
              <button onClick={() => onTransition(ticket.id, "served")}>{t.markServed}</button>
            )}
          </footer>
        </div>
      ))}
    </div>
  );
};
