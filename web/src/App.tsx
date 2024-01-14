import React, { useEffect, useState } from "react";
import { Locale, MenuItem, Station, TicketStatus } from "./types";
import { UI_LABELS } from "./i18n";
import { useStationChannel } from "./hooks/useStationChannel";
import { StationBoard } from "./components/StationBoard";
import "./styles.css";

const STATIONS: Station[] = ["all", "grill", "cold", "bar", "pastry"];
const LOCALES: Locale[] = ["en", "es", "sv"];
const DEMO_MODE_ENABLED =
  import.meta.env.VITE_DEMO_MODE === "true" ||
  new URLSearchParams(window.location.search).get("demo") === "true";

export const App: React.FC = () => {
  const [station, setStation] = useState<Station>("all");
  const [pickupView, setPickupView] = useState(false);
  const [locale, setLocale] = useState<Locale>("en");
  const [menuItems, setMenuItems] = useState<MenuItem[]>([]);
  const [demoCreating, setDemoCreating] = useState(false);
  const [demoNotice, setDemoNotice] = useState<string | null>(null);
  const { tickets, setTickets, connected } = useStationChannel(pickupView ? "all" : station);
  const t = UI_LABELS[locale];

  useEffect(() => {
    fetch(`/api/menu-items?lang=${locale}`)
      .then((r) => r.json())
      .then((body) => {
        setMenuItems(body.data || []);
      })
      .catch(() => {});
  }, [locale]);

  const itemNamesById: Record<string, string> = {};
  for (const item of menuItems) {
    itemNamesById[item.id] = item.display_name || item.name;
  }

  const handleTransition = async (ticketId: string, nextStatus: TicketStatus) => {
    const res = await fetch(`/api/tickets/${ticketId}/status?lang=${locale}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ status: nextStatus })
    });

    if (res.ok) {
      const body = await res.json();
      setTickets((prev) => prev.map((tk) => (tk.id === ticketId ? body.data : tk)));
    }
  };

  const handleSimulateOrder = async () => {
    if (demoCreating) return;
    setDemoCreating(true);
    try {
      const menuRes = await fetch(`/api/menu-items?lang=${locale}`);
      const menuBody = await menuRes.json();
      const items = menuBody.data || [];
      if (items.length === 0) return;

      const shuffled = [...items].sort(() => Math.random() - 0.5);
      const count = Math.min(shuffled.length, Math.floor(Math.random() * 3) + 2);
      const picked = shuffled.slice(0, count).map((m: { id: string }) => ({
        menu_item_id: m.id,
        quantity: Math.floor(Math.random() * 2) + 1
      }));

      const allTables = [1, 2, 3, 4, 5, 6, 7, 8];
      const activeTables = new Set(
        tickets
          .filter((tk) => tk.status !== "served" && tk.status !== "cancelled")
          .map((tk) => tk.table_number)
      );
      const freeTables = allTables.filter((n) => !activeTables.has(n));
      const pool = freeTables.length > 0 ? freeTables : allTables;
      const tableNum = pool[Math.floor(Math.random() * pool.length)];

      const res = await fetch(`/api/orders?lang=${locale}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          order: {
            table_number: tableNum,
            items: picked
          }
        })
      });

      if (res.ok) {
        const created = await res.json();
        const orderData = created.data;
        const shortId = (orderData?.id || "").slice(0, 4).toUpperCase();
        const routedStations = (orderData?.station_tickets || [])
          .map((tk: { station: string }) => t[tk.station] || tk.station)
          .join(", ");
        setDemoNotice(
          `${t.table} #${tableNum} · ${t.order} #${shortId} → ${routedStations}`
        );
        window.setTimeout(() => setDemoNotice(null), 4000);
      }
    } finally {
      setDemoCreating(false);
    }
  };

  return (
    <div>
      <header className="topbar">
        <div className="brand">
          <span className={`status-dot ${connected ? "online" : ""}`} />
          <strong>{t.title}</strong>
        </div>
        <nav className="station-tabs">
          <button
            className={pickupView ? "active" : ""}
            onClick={() => setPickupView(true)}
          >
            {t.pickup}
          </button>
          {STATIONS.map((st) => (
            <button
              key={st}
              className={!pickupView && station === st ? "active" : ""}
              onClick={() => {
                setPickupView(false);
                setStation(st);
              }}
            >
              {t[st]}
            </button>
          ))}
        </nav>
        <div className="topbar-right">
          {demoNotice && <span className="demo-toast">{demoNotice}</span>}
          {DEMO_MODE_ENABLED && (
            <button
              className="new-order-btn"
              onClick={handleSimulateOrder}
              disabled={demoCreating}
            >
              {demoCreating ? "..." : "+ Demo Order"}
            </button>
          )}
          <span className="locale-switch">
            {LOCALES.map((loc) => (
              <button
                key={loc}
                className={locale === loc ? "active" : ""}
                onClick={() => setLocale(loc)}
              >
                {loc.toUpperCase()}
              </button>
            ))}
          </span>
        </div>
      </header>
      <StationBoard
        tickets={tickets}
        locale={locale}
        itemNamesById={itemNamesById}
        groupByOrder={pickupView}
        onTransition={handleTransition}
      />
    </div>
  );
};
