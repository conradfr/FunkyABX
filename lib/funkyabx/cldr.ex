defmodule FunkyABX.Cldr do
  use Cldr,
    locales: ["en", "fr"],
    gettext: FunkyABXWeb.Gettext,
    providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime]
end
