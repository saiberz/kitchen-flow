import React, { useEffect, useState } from "react";
import { Locale, MenuItem, Station, TicketStatus } from "./types";
import { UI_LABELS } from "./i18n";
import { useStationChannel } from "./hooks/useStationChannel";
import { StationBoard } from "./components/StationBoard";
import "./styles.css";

const STATIONS: Station[] = ["all", "grill", "cold", "bar", "pastry"];
const LOCALES: Locale[] = ["en", "es", "sv"];

export const App: React.FC = () => {
  const [station, setStation] = useState<Station>("all");
  const [pickupView, setPickupView] = useState(false);
  const [locale, setLocale] = useState<Locale>("en");
  const [menuItems, setMenuItems] = useState<MenuItem[]>([]);
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
        <div>
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
