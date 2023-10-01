import { useEffect, useState } from "react";
import { Socket } from "phoenix";
import { Station, StationTicket } from "../types";

const getSocketUrl = (): string => {
  const envUrl = (import.meta as any).env?.VITE_WS_URL;
  if (envUrl) return envUrl;
  const isHttps = typeof window !== "undefined" && window.location.protocol === "https:";
  const host = typeof window !== "undefined" && window.location.hostname ? window.location.host : "localhost:4000";
  const wsHost = window.location.port === "5173" ? "localhost:4000" : host;
  return `${isHttps ? "wss:" : "ws:"}//${wsHost}/socket`;
};

export function useStationChannel(station: Station) {
  const [tickets, setTickets] = useState<StationTicket[]>([]);
  const [connected, setConnected] = useState(false);

  useEffect(() => {
    const socket = new Socket(getSocketUrl());
    socket.connect();

    const channel = socket.channel(`station:${station}`, {});

    channel
      .join()
      .receive("ok", (resp: { data: StationTicket[] }) => {
        setConnected(true);
        setTickets(resp.data || []);
      })
      .receive("error", () => {
        setConnected(false);
      });

    channel.on("ticket_created", (ticket: StationTicket) => {
      setTickets((prev) => [...prev, ticket]);
    });

    channel.on("ticket_updated", (updated: StationTicket) => {
      setTickets((prev) =>
        prev.map((t) => (t.id === updated.id ? updated : t))
      );
    });

    return () => {
      socket.disconnect();
    };
  }, [station]);

  return { tickets, setTickets, connected };
}
