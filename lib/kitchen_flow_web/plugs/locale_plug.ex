defmodule KitchenFlowWeb.Plugs.LocalePlug do
  import Plug.Conn

  @supported_locales ~w(en es sv)
  @default_locale "en"

  def init(opts), do: opts

  def call(conn, _opts) do
    locale =
      conn.params["lang"] ||
        extract_accept_language(conn) ||
        @default_locale

    resolved = if locale in @supported_locales, do: locale, else: @default_locale
    Gettext.put_locale(KitchenFlowWeb.Gettext, resolved)

    conn
    |> assign(:locale, resolved)
    |> put_resp_header("content-language", resolved)
  end

  defp extract_accept_language(conn) do
    case get_req_header(conn, "accept-language") do
      [header | _] ->
        header
        |> String.split(",")
        |> List.first()
        |> to_string()
        |> String.slice(0, 2)
        |> String.downcase()

      [] ->
        nil
    end
  end
end
