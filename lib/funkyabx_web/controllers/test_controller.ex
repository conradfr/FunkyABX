defmodule FunkyABXWeb.TestController do
  require Logger

  use FunkyABXWeb, :controller
  use PhoenixSwagger

  import Ecto.Changeset

  alias Ecto.UUID
  alias FunkyABX.Repo
  alias FunkyABX.{Tests, Test, Files, Tracks}
  alias FunkyABX.Accounts.User

  @cookie_prefix "token_test_"

  def swagger_definitions do
    %{
      Test:
        swagger_schema do
          title("Test")
          description("")

          properties do
            title(:string, "Track's name", required: true)
            author(:string, "Audio file's name", required: false)
            description(:string, "", required: false)

            description_markdown(:boolean, "True if using markdown formating",
              required: false,
              default: false
            )

            public(:boolean, "Test is published in the gallery", required: false, default: false)

            email_notification(:boolean, "Email notification when a test is taken",
              required: false,
              default: false
            )

            password_enabled(:boolean, "Test id protected by a password",
              required: false,
              default: false
            )

            password(:string, "", required: false)

            type(:integer, "1: regular, 2: abx, 3: listening", required: false, default: 1)
            regular_type(:integer, "1: rank, 2: pick, 3: star", required: false, default: 1)

            anonymized_track_title(:boolean, "Track's title not showed (only ABX tests)",
              required: false,
              default: true
            )

            #            rating(:boolean, "", required: false, default: false)
            identification(:boolean, "Add track identification (only regular tests)",
              required: false,
              default: false
            )

            ranking_only_extremities(
              :boolean,
              "Rank only the top/bottom 3 tracks for tests with 10+ tracks (only regular ranking tests)",
              required: false,
              default: false
            )

            nb_of_rounds(:integer, "Number of rounds (ABX tests only)",
              required: false,
              default: 10
            )

            normalization(
              :boolean,
              "Apply EBU R128 loudness normalization during upload (wav files only)",
              required: false,
              default: false
            )
          end
        end,
      Track:
        swagger_schema do
          title("Track")
          description("")

          properties do
            title(:string, "Track's name", required: false)
            filename(:string, "audio file's name", required: true)
            data(:string, "base64 encoded audio data", required: true)
          end
        end
    }
  end

  swagger_path :test_api_new do
    post("/test")
    description("Submit new test")
    parameters do
      test :path, :object, "Test", required: true
      tracks :path, :array, "Array of Tracks", required: true,
        type: Schema.ref(:Tracks)
    end
    response(400, "Bad request")
    response(201, "Created",
      swagger_schema do
        properties do
          status(:string, "OK")
          id(:string, "Test's id")
          _links(:array, "Links to pages")
        end
      end
    )
  end

  def test_api_new(conn, %{"test" => test_params, "tracks" => tracks_params} = _params) do
    with %User{} = user <- Map.get(conn.private, :user) do
      request_ip = fetch_session(conn, "visitor_ip") || nil
      test_id = UUID.generate()
      normalization = Map.get(test_params, "normalization", false)

      tracks_parsed =
        tracks_params
        |> Enum.map(fn t -> Tracks.parse_and_import_tracks_from_api(t, test_id, normalization) end)

      test_params_updated =
        test_params
        |> Map.put("tracks", tracks_parsed)
        |> Map.merge(%{
          "ip_address" => request_ip
        })

      test_changeset =
        Test.new(user)
        |> Test.changeset(test_params_updated)

      case test_changeset.valid? do
        true ->
          {:ok, test} = Repo.insert(test_changeset)

          Logger.info("Test created via the API (##{test_id})")

          conn
          |> put_status(:created)
          |> json(%{
            "status" => "OK",
            "id" => test_id,
            "_links" => %{
              "public" => Routes.test_public_url(conn, FunkyABXWeb.TestLive, test.slug),
              "public_embed" => Routes.test_public_url(conn, FunkyABXWeb.TestLive, test.slug, embed: "1"),
              "edit" => Routes.test_edit_url(conn, FunkyABXWeb.TestFormLive, test.id),
              "results" =>
                Routes.test_results_public_url(conn, FunkyABXWeb.TestResultsLive, test.slug)
            }
          })

        false ->
          Files.delete_all(test_id)

          Logger.info("Invalid test creation request via the API")

          conn
          |> put_status(:bad_request)
          |> json(%{
            "status" => "Error",
            errors:
              traverse_errors(test_changeset, fn {msg, opts} ->
                Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
                  opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
                end)
              end)
          })
      end
    else
      _ ->
        conn
        |> put_status(:bad_request)
        |> json(%{"status" => "Error"})
    end
  end

  def password(conn, %{"slug" => slug}) do
    with test when not is_nil(test) <- Tests.get_by_slug(slug),
         false <- is_nil(test.password),
         nil <- test.deleted_at do
      render(conn, "password.html", test: test)
    else
      _ ->
        conn
        |> put_status(:not_found)
        |> Phoenix.Controller.put_view(FunkyABXWeb.ErrorView)
        |> Phoenix.Controller.render(:"404")
        |> halt()
    end
  end

  def password_verify(
        conn,
        %{"slug" => slug, "password" => password, "referer" => referer} = _params
      ) do
    with test when not is_nil(test) <- Tests.get_by_slug(slug),
         false <- is_nil(test.password),
         nil <- test.deleted_at do
      if Pbkdf2.verify_pass(password, test.password) do
        conn
        |> put_session(@cookie_prefix <> test.id, Base.encode64(test.password))
        |> put_resp_cookie(@cookie_prefix <> test.id, Base.encode64(test.password))
        |> redirect(to: referer)
      else
        render(conn, "password.html", test: test, error_message: "Wrong password :(")
      end
    else
      _ ->
        conn
        |> put_status(:not_found)
        |> Phoenix.Controller.put_view(FunkyABXWeb.ErrorView)
        |> Phoenix.Controller.render(:"404")
        |> halt()
    end
  end

  #      if user = Accounts.get_user_by_email_and_password(email, password) do
  #        UserAuth.log_in_user(conn, user, user_params)
  #      else
  #        # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
  #        render(conn, "new.html", error_message: "Invalid email or password")
  #      end
end
