defmodule FunkyABXWeb.RestoreLocale do
  def on_mount(:default, _params, session, socket) do
    with locale_name when is_binary(locale_name) <- Map.get(session, "cldr_locale"),
         {:ok, locale} <- FunkyABX.Cldr.validate_locale(locale_name) do
      FunkyABX.Cldr.put_locale(locale)

      if locale.gettext_locale_name do
        Gettext.put_locale(FunkyABXWeb.Gettext, locale.gettext_locale_name)
      end
    end

    {:cont, socket}
  end
end
