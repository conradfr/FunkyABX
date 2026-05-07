defmodule FunkyABX.Cldr do
  use Cldr,
    locales: ["en", "fr", "es", "ja"],
    gettext: FunkyABXWeb.Gettext,
    providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime]
end
