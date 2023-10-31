defmodule FunkyABX.Tests.Abx do
  import Ecto.Query, only: [dynamic: 2, from: 2]

  alias FunkyABX.Repo
  alias FunkyABX.Tests.Image
  alias FunkyABX.{Test, Tracks, AbxDetails}
  alias FunkyABX.Abx, as: AbxSchema

  @behaviour FunkyABX.Tests.Type

  @p_value 0.5

  # ---------- GET ----------

  def get_abx(%Test{} = test) do
    query =
      from a in AbxSchema,
        join: t in Test,
        on: t.id == a.test_id,
        where: t.id == ^test.id,
        order_by: [
          desc: a.count,
          desc: a.correct
        ],
        select: %{
          correct: a.correct,
          count: a.count
        }

    result =
      query
      |> Repo.all()

    # I have no idea what I'm doing and why I have to reverse this list to get the correct value

    values_inverse =
      result
      |> Enum.map(fn a ->
        Statistics.Distributions.Binomial.cdf(test.nb_of_rounds, @p_value).(a.correct)
      end)
      |> Enum.reverse()

    # Add ABX Binomial Probability
    result
    |> Enum.with_index()
    |> Enum.map(fn {a, k} ->
      probability =
        values_inverse
        |> Enum.at(k)
        |> format_probability()

      Map.put(a, :probability, probability)
    end)
  end

  # ---------- TEST MODULES ----------

  @impl true
  def get_test_modules(_test), do: [FunkyABX.Tests.Abx]

  # ---------- CHOICE MODULES ----------

  @impl true
  def get_choices_modules(_test), do: [FunkyABXWeb.TestTrackAbxComponent]

  # ---------- RESULT MODULES ----------

  @impl true
  def get_result_modules(_test), do: [FunkyABXWeb.TestResultAbxComponent]

  # ---------- PARAMS ----------

  @impl true
  def get_test_params(_test) do
    %{
      has_choices: true,
      draw_waveform: false
    }
  end

  @impl true
  def can_have_reference_track?(), do: false

  # ---------- TAKEN ----------

  @impl true
  def get_how_many_taken(%Test{} = test) do
    query =
      from a in AbxSchema,
        where: a.test_id == ^test.id,
        select: fragment("COALESCE(SUM(?), 0)", a.count)

    query
    |> Repo.one()
  end

  # ---------- TRACKS ----------

  @impl true
  def prep_tracks(tracks, _test) when is_list(tracks) do
    picked =
      tracks
      |> Enum.random()
      |> Map.put(:fake_id, nil)
      |> Map.put(:to_guess, true)
      |> Tracks.prep_track()
      |> Map.put(:title, "X")

    tracks ++ [picked]
  end

  # ---------- FORM ----------

  # todo enforce nb of rounds

  @impl true
  def is_valid?(_test, round, choices) when is_map_key(choices, round) do
    case Map.get(choices[round], :abx, nil) do
      nil -> false
      {"", _guessed} -> false
      _ -> true
    end
  end

  @impl true
  def is_valid?(_test, _round, _choices), do: false

  # ---------- SAVE ----------

  @impl true
  def clean_choices(choices, _tracks, _test) do
    choices
    |> Enum.reduce(%{}, fn {r, c}, acc ->
      {_track_id, round_result} = c.abx
      Map.put(acc, r, round_result)
    end)
  end

  @impl true
  def submit(%Test{} = test, choices, session_id, ip_address) do
    correct_guesses =
      choices
      |> Enum.count(fn {_track_id, round_result} ->
        round_result
      end)

    # we insert a new entry or increase the count if this combination of test + guesses exists
    on_conflict = [set: [count: dynamic([r], fragment("? + ?", r.count, 1))]]

    {:ok, _updated} =
      Repo.insert(%AbxSchema{test: test, correct: correct_guesses, count: 1},
        on_conflict: on_conflict,
        conflict_target: [:test_id, :correct]
      )

    %AbxDetails{test: test}
    |> AbxDetails.changeset(%{
      rounds: choices,
      session_id: session_id,
      ip_address: ip_address
    })
    |> Repo.insert()
  end

  # ---------- RESULTS ----------

  @impl true
  def get_results(%Test{} = test, session_id) when is_binary(session_id) do
    query =
      from ad in AbxDetails,
        where: ad.test_id == ^test.id and ad.session_id == ^session_id,
        select: ad.rounds

    result =
      query
      |> Repo.one()

    case result do
      nil -> %{}
      _ -> result
    end
  end

  def results_to_img(mogrify_params, %Test{} = test, session_id, choices)
      when is_binary(session_id) do
    {start, mogrify} = mogrify_params

    guessed =
      choices
      |> Map.values()
      |> Enum.count(fn round_result ->
        round_result
      end)

    mogrify =
      mogrify
      |> Image.type_title(start, "Abx")
      |> Image.type_track(start, 1, "Correct guesses: #{guessed}/#{test.nb_of_rounds}")

    {start + 46, mogrify}
  end

  # ---------- UTILS ----------

  defp format_probability(probability) when is_number(probability) do
    probability_percent = (1 - probability) * 100

    :io_lib.format("~.2f", [probability_percent])
    |> IO.iodata_to_binary()
  end
end
