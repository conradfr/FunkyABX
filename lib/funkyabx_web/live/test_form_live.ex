defmodule FunkyABXWeb.TestFormLive do
  import Ecto.Changeset
  require Logger
  use FunkyABXWeb, :live_view
  import Phoenix.HTML.Form

  alias Ecto.UUID
  alias Phoenix.LiveView.JS
  alias FunkyABX.Repo

  alias FunkyABX.Tests.FormUtils
  alias FunkyABX.{Accounts, Utils, Urls, Tests, Files, Tracks, TestClosingWorker}
  alias FunkyABX.{Test, Track}

  @title_max_length 100

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.form
        :let={f}
        class="mb-2"
        for={@changeset}
        phx-change="validate"
        phx-submit={@action}
        id="test-form"
        phx-hook="TestForm"
      >
        <input
          type="hidden"
          id={input_id(f, :access_key)}
          name={input_name(f, :access_key)}
          value={input_value(f, :access_key)}
        />

        <div class="row">
          <div class="col-12 order-md-1 order-2">
            <h2 class="mb-2 mt-0 header-chemyretro">
              <%= if @action == "save" do %>
                {dgettext("test", "Create a new test")}
              <% else %>
                {dgettext("test", "Edit a test")}
              <% end %>
            </h2>

            <%= if @action == "save" do %>
              <div class="alert alert-info alert-thin">
                <i class="bi bi-info-circle"></i>&nbsp;&nbsp;{raw(
                  dgettext(
                    "test",
                    "If you're making a one-off test for yourself, consider making a <a href=\"%{link}\">local test</a>, it's quicker and avoids uploading your files.",
                    link: ~p"/local_test"
                  )
                )}
              </div>
            <% end %>
          </div>
        </div>

        <%= if @action == "update" do %>
          <div class="row">
            <div class="col-md-6 col-m-12">
              <fieldset class="form-group mb-3">
                <%= unless @test.view_count == nil do %>
                  <legend class="header-typographica">
                    <div
                      class="float-end fs-8 text-body-secondary"
                      style="font-family: var(--bs-font-sans-serif); padding-top: 12px;"
                    >
                      {raw(
                        dngettext(
                          "test",
                          "Test played <strong>%{count}</strong> time",
                          "Test played <strong>%{count}</strong> times",
                          @test.view_count
                        )
                      )}
                    </div>
                    {dgettext("test", "Links")}
                  </legend>
                <% end %>
                <div class="px-3 pt-2 pb-3 rounded-3" style="background-color: #583247;">
                  <div class="mb-3">
                    <label
                      for="test_public_link"
                      class="form-label d-flex justify-content-between align-items-center w-100"
                    >
                      <div>
                        {dgettext("test", "Test public page")}
                        <span class="form-text">{dgettext("test", "(share this link)")}</span>
                      </div>
                      <div class="d-flex align-items-center">
                        <.input
                          field={f[:embed]}
                          type="checkbox"
                          label={dgettext("test", "Embed")}
                        />

                        <.input
                          :if={get_field(@changeset, :type) == :listening}
                          disabled={input_value(f, :embed) !== "true"}
                          field={f[:embed_type]}
                          type="select"
                          class="ms-2 form-select form-select-sm"
                          class_wrapper="fieldset"
                          options={[
                            {dgettext("test", "Test"), "test"},
                            {dgettext("test", "Player only"), "player"}
                          ]}
                        />

                        <i
                          class="bi bi-info-circle text-body-secondary ms-2"
                          data-bs-toggle="tooltip"
                          title={
                            dgettext(
                              "site",
                              "Use rotate=0 and loop=0 to set rotating and looping as off by default"
                            )
                          }
                        >
                        </i>
                      </div>
                    </label>
                    <% test_url =
                      if input_value(f, :embed) == "true" do
                        embed_value = if input_value(f, :embed_type) == "player", do: "2", else: "1"
                        url(~p"/test/#{input_value(f, :slug)}?embed=#{embed_value}")
                      else
                        url(~p"/test/#{input_value(f, :slug)}")
                      end %>
                    <div class="input-group mb-3">
                      <input
                        type="url"
                        class="form-control"
                        name="public_link"
                        value={test_url}
                        readonly
                      />
                      <button
                        class="btn btn-info"
                        type="button"
                        title={dgettext("site", "Copy to clipboard")}
                        phx-click="clipboard"
                        phx-value-text={test_url}
                      >
                        <i class="bi bi-clipboard"></i>
                      </button>
                      <a
                        class="btn btn-light"
                        type="button"
                        target="_blank"
                        title={dgettext("site", "Open in a new tab")}
                        href={test_url}
                      >
                        <i class="bi bi-box-arrow-up-right"></i>
                      </a>
                    </div>
                  </div>
                  <div class="mb-3">
                    <label for="test_edit_link" class="form-label">
                      {dgettext("test", "Test edit page")}
                      <span class="form-text">{dgettext("test", "(this page)")}</span>
                    </label>
                    <div class="input-group mb-3">
                      <%= if @current_user do %>
                        <input
                          type="url"
                          class="form-control"
                          name="edit_link"
                          value={url(~p"/edit/#{input_value(f, :slug)}")}
                          readonly
                        />
                        <button
                          class="btn btn-info"
                          type="button"
                          title={dgettext("site", "Copy to clipboard")}
                          phx-click="clipboard"
                          phx-value-text={url(~p"/edit/#{input_value(f, :slug)}")}
                        >
                          <i class="bi bi-clipboard"></i>
                        </button>
                        <a
                          class="btn btn-light"
                          type="button"
                          target="_blank"
                          title={dgettext("site", "Open in a new tab")}
                          href={url(~p"/edit/#{input_value(f, :slug)}")}
                        >
                          <i class="bi bi-box-arrow-up-right"></i>
                        </a>
                      <% else %>
                        <input
                          type="url"
                          class="form-control"
                          name="edit_link"
                          value={
                            url(~p"/edit/#{input_value(f, :slug)}/#{input_value(f, :access_key)}")
                          }
                          readonly
                        />
                        <button
                          class="btn btn-info"
                          type="button"
                          title={dgettext("site", "Copy to clipboard")}
                          phx-click="clipboard"
                          phx-value-text={
                            url(~p"/edit/#{input_value(f, :slug)}/#{input_value(f, :access_key)}")
                          }
                        >
                          <i class="bi bi-clipboard"></i>
                        </button>
                        <a
                          class="btn btn-light"
                          type="button"
                          target="_blank"
                          title={dgettext("site", "Open in a new tab")}
                          href={
                            url(~p"/edit/#{input_value(f, :slug)}/#{input_value(f, :access_key)}")
                          }
                        >
                          <i class="bi bi-box-arrow-up-right"></i>
                        </a>
                      <% end %>
                    </div>
                  </div>
                  <%= unless get_field(@changeset, :type) == "listening" or get_field(@changeset, :hide_global_results) == true do %>
                    <div>
                      <label for="" class="form-label">
                        {dgettext("test", "Test private results page")}
                        <span class="form-text">
                          {dgettext("test", "(if you don't take the test)")}
                        </span>
                      </label>
                      <div class="input-group">
                        <%= if @current_user do %>
                          <input
                            type="url"
                            class="form-control"
                            name="results_link"
                            value={url(~p"/results/#{input_value(f, :slug)}")}
                            readonly
                          />
                          <button
                            class="btn btn-info"
                            type="button"
                            title={dgettext("site", "Copy to clipboard")}
                            phx-click="clipboard"
                            phx-value-text={url(~p"/results/#{input_value(f, :slug)}")}
                          >
                            <i class="bi bi-clipboard"></i>
                          </button>
                          <a
                            class="btn btn-light"
                            type="button"
                            target="_blank"
                            title={dgettext("site", "Open in a new tab")}
                            href={url(~p"/results/#{input_value(f, :slug)}")}
                          >
                            <i class="bi bi-box-arrow-up-right"></i>
                          </a>
                        <% else %>
                          <input
                            type="url"
                            class="form-control"
                            name="results_link"
                            value={
                              url(
                                ~p"/results/#{input_value(f, :slug)}/#{input_value(f, :access_key)}"
                              )
                            }
                            readonly
                          />
                          <button
                            class="btn btn-info"
                            type="button"
                            title={dgettext("site", "Copy to clipboard")}
                            phx-click="clipboard"
                            phx-value-text={
                              url(
                                ~p"/results/#{input_value(f, :slug)}/#{input_value(f, :access_key)}"
                              )
                            }
                          >
                            <i class="bi bi-clipboard"></i>
                          </button>
                          <a
                            class="btn btn-light"
                            type="button"
                            target="_blank"
                            title={dgettext("site", "Open in a new tab")}
                            href={
                              url(
                                ~p"/results/#{input_value(f, :slug)}/#{input_value(f, :access_key)}"
                              )
                            }
                          >
                            <i class="bi bi-box-arrow-up-right"></i>
                          </a>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                </div>
              </fieldset>
            </div>
            <div class="col-md-6 col-m-12">
              <fieldset class="form-group mb-3">
                <legend class="header-typographica">
                  {dgettext("test", "Actions")}
                </legend>
                <div class="px-3 py-2 pt-1 rounded-3 text-center" style="background-color: #583247;">
                  <div if={get_field(@changeset, :type) !== :listening} class="mb-3 mt-3">
                    <button
                      :if={
                        get_field(@changeset, :type) !== :listening and
                          Tests.is_closed?(@test) == false
                      }
                      type="button"
                      class="btn btn-warning w-100"
                      data-confirm={dgettext("site", "Are you sure?")}
                      phx-click="close_test"
                    >
                      <i class="bi bi-x-circle"></i>&nbsp;&nbsp;{dgettext("test", "Close the test")}
                    </button>
                    <button
                      :if={
                        get_field(@changeset, :type) !== :listening and
                          Tests.is_closed?(@test) == true
                      }
                      type="button"
                      class="btn btn-warning w-100"
                      data-confirm={dgettext("site", "Are you sure?")}
                      phx-click="close_test"
                    >
                      <i class="bi bi-check-circle"></i>&nbsp;&nbsp;{dgettext(
                        "test",
                        "Reopen the test"
                      )}
                    </button>
                  </div>
                  <div>
                    <button
                      type="button"
                      class="btn btn-danger w-100"
                      data-confirm={dgettext("site", "Are you sure?")}
                      phx-click="delete_test"
                    >
                      <i class="bi bi-trash"></i>&nbsp;&nbsp;{dgettext("test", "Delete the test")}
                    </button>
                  </div>
                  <hr />
                  <div>
                    <button
                      type="button"
                      class={["btn btn-info w-100"]}
                      phx-click={JS.dispatch("open_modal", to: "body")}
                    >
                      <i class="bi bi-envelope"></i>&nbsp;&nbsp;{dgettext(
                        "test",
                        "Generate invitations"
                      )}
                    </button>
                  </div>
                </div>
              </fieldset>
            </div>
          </div>
        <% end %>

        <div class="row">
          <div class="col-12">
            <fieldset class="form-group mb-3">
              <legend class="mt-1 header-typographica">{dgettext("test", "Infos")}</legend>
              <div class="form-unit p-3 pb-2 rounded-3">
                <div class="row mb-3">
                  <div class="col-12 col-md-6">
                    <.input
                      field={f[:title]}
                      type="text"
                      label={dgettext("test", "Title*")}
                      placeholder={dgettext("test", "(mandatory)")}
                      required
                    />
                    {error_tag(f, :title)}
                  </div>
                  <div class="col-12 col-md-6 pt-3 pt-md-0">
                    <.input
                      field={f[:author]}
                      type="text"
                      label={dgettext("test", "Created by")}
                      placeholder={dgettext("test", "(optional)")}
                      required
                    />
                  </div>
                </div>
                <div class="mb-2">
                  <.input
                    field={f[:description]}
                    type="textarea"
                    label={dgettext("test", "Description")}
                    placeholder={dgettext("test", "(optional)")}
                    rows="5"
                  />
                </div>
              </div>
            </fieldset>
          </div>
        </div>

        <div class="row">
          <div class="col-md-6 col-sm-12">
            <fieldset class="form-group mb-3">
              <legend class="mt-1 header-typographica">{dgettext("test", "Test type")}</legend>
              <%= if @test_updatable == false do %>
                <div class="alert alert-warning alert-thin">
                  <i class="bi bi-x-circle"></i>&nbsp;&nbsp;{dgettext(
                    "test",
                    "Test type can't be changed once at least one person has taken the test."
                  )}
                </div>
              <% end %>
              <div class="form-unit px-3 py-3 rounded-3">
                <div class="form-check">
                  <label class="form-check-label">
                    <input
                      type="radio"
                      name={input_name(f, :type)}
                      class="form-check-input"
                      value="regular"
                      checked={get_field(@changeset, :type) == :regular}
                      disabled={!@test_updatable}
                    />
                    {dgettext("test", "Blind test")}
                  </label>
                  {error_tag(f, :type)}
                </div>
                <div class="fs-8 mb-2 text-body-secondary ms-4 mb-1">
                  <i class="bi bi-info-circle"></i>&nbsp;&nbsp;Select at least one option
                </div>
                <div class="form-check ms-4">
                  <.input
                    field={f[:rating]}
                    type="checkbox"
                    label={dgettext("test", "Rating")}
                    disabled={!@test_updatable or get_field(@changeset, :type) !== :regular}
                  />

                  <div class="form-check mt-2 ms-1">
                    <label class="form-check-label">
                      <input
                        type="radio"
                        name={input_name(f, :regular_type)}
                        class="form-check-input"
                        value="pick"
                        checked={get_field(@changeset, :regular_type) == :pick}
                        disabled={
                          !@test_updatable or get_field(@changeset, :rating) != true or
                            get_field(@changeset, :type) !== :regular
                        }
                      />
                      {dgettext("test", "Picking")}
                    </label>
                    <div class="form-text mb-2">
                      {dgettext("test", "People will have to pick their preferred track")}
                    </div>
                  </div>

                  <div class="form-check ms-1">
                    <label class="form-check-label">
                      <input
                        type="radio"
                        name={input_name(f, :regular_type)}
                        class="form-check-input"
                        value="star"
                        checked={get_field(@changeset, :regular_type) == :star}
                        disabled={
                          !@test_updatable or get_field(@changeset, :rating) != true or
                            get_field(@changeset, :type) !== :regular
                        }
                      />
                      {dgettext("test", "Stars")}
                    </label>
                    <div class="form-text mb-2">
                      {dgettext(
                        "test",
                        "Each track will have a 1-5 star rating (usually NOT the best choice !)"
                      )}
                    </div>
                  </div>

                  <div class="form-check ms-1">
                    <label class="form-check-label">
                      <input
                        type="radio"
                        name={input_name(f, :regular_type)}
                        class="form-check-input"
                        value="rank"
                        checked={get_field(@changeset, :regular_type) == :rank}
                        disabled={
                          !@test_updatable or get_field(@changeset, :rating) != true or
                            get_field(@changeset, :type) !== :regular
                        }
                      />
                      {dgettext("test", "Ranking ")}
                    </label>
                    <div class="form-text mb-2">
                      {dgettext("test", "People will be asked to rank the tracks")}
                    </div>
                    <div class="form-check ms-4">
                      <.input
                        field={f[:ranking_only_extremities]}
                        type="checkbox"
                        label={dgettext("test", "Only rank the top/bottom three tracks")}
                        disabled={
                          !@test_updatable or get_field(@changeset, :rating) != true or
                            get_field(@changeset, :type) !== :regular or
                            Kernel.length(get_field(@changeset, :tracks)) < 10
                        }
                      />
                      <div class="form-text mb-2">
                        {dgettext("test", "Only for tests with 10+ tracks")}
                      </div>
                    </div>
                  </div>
                </div>
                <div class="form-check ms-4">
                  <.input
                    field={f[:identification]}
                    type="checkbox"
                    label={dgettext("test", "Recognition test")}
                    disabled={!@test_updatable or get_field(@changeset, :type) !== :regular}
                  />
                  <div class="form-text mb-2">
                    {dgettext("test", "People will have to identify the anonymized tracks")}
                  </div>
                </div>

                <div class="form-check disabled ps-0 mt-4 mb-2">
                  <label class="form-check-label">
                    <input
                      type="radio"
                      name={input_name(f, :type)}
                      class="radio radio-xs me-2"
                      value="abx"
                      checked={get_field(@changeset, :type) == :abx}
                      disabled={!@test_updatable}
                    />
                    {dgettext("test", "ABX test")}
                  </label>
                  <div class="form-text mb-2 ps-4">
                    {dgettext("test", "People will have to guess which track is cloned for n rounds")}
                  </div>
                  <div class="row ms-5 mb-1">
                    <label for="test[nb_of_rounds]" class="col-6 col-sm-4 col-form-label ps-0">
                      {dgettext("test", "Number of rounds:")}
                    </label>
                    <div class="col-6 col-sm-2">
                      <.input
                        field={f[:nb_of_rounds]}
                        type="number"
                        class="form-control"
                        title={dgettext("test", "Must be between be 1 to 10")}
                        required={get_field(@changeset, :type) == :abx}
                        disabled={!@test_updatable or get_field(@changeset, :type) !== :abx}
                      />
                    </div>
                  </div>
                  <div class="form-check mt-2 ms-5 mb-3">
                    <.input
                      field={f[:anonymized_track_title]}
                      type="checkbox"
                      label={dgettext("test", "Hide tracks' title")}
                      disabled={!@test_updatable or get_field(@changeset, :type) !== :abx}
                    />
                  </div>
                </div>

                <div class="form-check disabled mt-4">
                  <label class="form-check-label">
                    <input
                      type="radio"
                      name={input_name(f, :type)}
                      class="form-check-input"
                      value="listening"
                      checked={get_field(@changeset, :type) == :listening}
                      disabled={!@test_updatable}
                    />
                    {dgettext("test", "No test, only listening")}
                  </label>
                </div>
              </div>
            </fieldset>
          </div>
          <div class="col-md-6 col-sm-12 order-md-1 order-2">
            <fieldset class="form-group mb-3">
              <legend class="mt-1 header-typographica">{dgettext("test", "Options")}</legend>
              <div class="form-unit p-3 rounded-3">
                <div class="form-check mb-3">
                  <.input
                    field={f[:public]}
                    type="checkbox"
                    label={dgettext("test", "The test is public")}
                  />
                  <div class="form-text">
                    {dgettext(
                      "test",
                      "It will be published in the gallery 15 minutes after its creation"
                    )}
                  </div>
                </div>

                <div class="form-check mb-3">
                  <.input
                    field={f[:allow_comments]}
                    type="checkbox"
                    label={dgettext("test", "Allow comments")}
                  />
                  <div class="form-text">
                    {dgettext(
                      "test",
                      "Comments are displayed on the results page (except for listening tests)"
                    )}
                  </div>
                </div>

                <div class="form-check mb-3">
                  <.input
                    field={f[:email_notification]}
                    type="checkbox"
                    disabled={@test.user == nil}
                    label={dgettext("test", "Notify me by email when a test is taken")}
                  />
                  <div :if={@test.user == nil} class="form-text">
                    {dgettext("test", "Available only for logged in users")}
                  </div>
                </div>

                <div class="form-check mb-3">
                  <.input
                    field={f[:email_notification_comments]}
                    type="checkbox"
                    disabled={@test.user == nil}
                    label={
                      dgettext("test", "Notify me by email when someone post a comment on a test")
                    }
                  />
                  <div :if={@test.user == nil} class="form-text">
                    {dgettext("test", "Available only for logged in users")}
                  </div>
                </div>

                <div class="form-check mb-3">
                  <.input
                    field={f[:hide_global_results]}
                    type="checkbox"
                    label={dgettext("test", "Visitors can only see their own test results.")}
                  />
                  <div class="form-text">
                    {dgettext(
                      "test",
                      "Global results and stats of the test will be hidden (even for you)"
                    )}
                  </div>
                </div>

                <div class="form-check mb-3">
                  <.input
                    field={f[:allow_retake]}
                    type="checkbox"
                    label={dgettext("test", "Allow a visitor to take the test multiple times")}
                  />
                </div>

                <div class="form-check mb-3">
                  <.input
                    field={f[:password_enabled]}
                    type="checkbox"
                    label={dgettext("test", "Password protected")}
                  />
                  <div class="form-text">
                    {dgettext(
                      "test",
                      "The test will require a password to be taken (public tests will be modified as private)"
                    )}
                  </div>
                </div>
                <input
                  type="hidden"
                  id={input_id(f, :password_length)}
                  name={input_name(f, :password_length)}
                  value={input_value(f, :password_length)}
                />
                <%= if @test.password_enabled == true and @test.password_length != nil do %>
                  <div class="form-check mt-2 mb-3">
                    {dgettext("test", "Current:")}&nbsp;
                    <%= for _star <- 1..@test.password_length do %>
                      *
                    <% end %>
                  </div>
                <% end %>
                <div class="form-check mt-2 mb-3">
                  <.input
                    field={f[:password_input]}
                    type="password"
                    class="form-control w-75"
                    placeholder={dgettext("test", "Enter new password")}
                  />
                  {error_tag(f, :password_input)}
                </div>

                <%= if get_field(@changeset, :type) != :listening do %>
                  <div class="form-check">
                    <.input
                      field={f[:to_close_at_enabled]}
                      type="checkbox"
                      label={dgettext("test", "Close the test at date/time")}
                    />
                    <div class="form-text">
                      {dgettext(
                        "test",
                        "The test won't be able to be taken after this date/time, but results will still be available"
                      )}
                    </div>
                  </div>
                  <div class="form-check mt-2 mb-1">
                    <.input
                      field={f[:to_close_at]}
                      type="datetime-local"
                      class="form-control w-75"
                    />
                    {error_tag(f, :to_close_at)}
                  </div>
                <% end %>
              </div>
            </fieldset>
          </div>
        </div>

        <fieldset>
          <legend class="header-typographica">
            <span
              class="float-end fs-8 text-body-secondary"
              style="font-family: var(--bs-font-sans-serif); padding-top: 12px;"
            >
              <i class="bi bi-info-circle"></i>&nbsp;{dgettext("test", "Two tracks minimum")}
            </span>
            Tracks
          </legend>

          <%= if @test_updatable == false do %>
            <div class="alert alert-warning alert-thin">
              <i class="bi bi-x-circle"></i>&nbsp;&nbsp;{dgettext(
                "test",
                "Tracks can't be added or removed once at least one person has taken the test."
              )}
            </div>
          <% else %>
            <div class="alert alert-info alert-thin">
              <i class="bi bi-info-circle"></i>&nbsp;&nbsp;{dgettext(
                "test",
                "Supported formats: wav, mp3, aac, flac ... "
              )} <a
                href="https://en.wikipedia.org/wiki/HTML5_audio#Supported_audio_coding_formats"
                target="_blank"
              >(html5 audio)</a>. {dgettext("test", "Wav files are converted to flac (16bits 48k).")}
            </div>
          <% end %>

          <fieldset class="form-group mb-3">
            <div class="form-unit p-3 rounded-3">
              <div class="form-check">
                <div class="d-flex justify-content-between">
                  <div>
                    <.input
                      field={f[:normalization]}
                      type="checkbox"
                      class_wrapper="pt-2"
                      label={
                        dgettext(
                          "test",
                          "Apply EBU R128 loudness normalization during upload (wav files only)"
                        )
                      }
                    />
                  </div>
                  <div class="text-body-secondary text-end">
                    <small>
                      <i class="bi bi-info-circle"></i>&nbsp; {dgettext(
                        "test",
                        "True Peak -1dB, target -24dB"
                      )}
                    </small>
                  </div>
                </div>
              </div>
            </div>
          </fieldset>
        </fieldset>

        <div class="row">
          <div class="col-md-6 col-sm-12 order-md-1 order-2">
            <fieldset class="form-group mb-3">
              <div class="form-unit p-3 pb-2 rounded-3">
                <div class="row form-unit pb-1 rounded-3" phx-drop-target={@uploads.tracks.ref}>
                  <label class="col-sm-4 col-form-label text-start text-md-end">
                    {dgettext("test", "Select file(s) to upload:")}
                  </label>
                  <div :if={@test_updatable} class="col text-center pt-1">
                    <.live_file_input upload={@uploads.tracks} />
                  </div>
                  <div :if={!@test_updatable} class="col text-center pt-1">
                    <input type="file" disabled />
                  </div>
                  <div class="col-1 text-center col-form-label d-none d-sm-block">
                    <i
                      class="bi bi-info-circle text-body-secondary"
                      data-bs-toggle="tooltip"
                      title={dgettext("site", "Or drag and drop files here")}
                    >
                    </i>
                  </div>
                </div>
              </div>
            </fieldset>
          </div>

          <div class="col-md-6 col-sm-12 order-md-1 order-2">
            <fieldset class="form-group mb-3">
              <div class="form-unit p-3 pb-2 rounded-3">
                <div class="row form-unit pb-1 rounded-3">
                  <label class="col-sm-4 col-form-label text-start text-md-end mt-2 mt-md-0">
                    {dgettext("test", "Add file from url:")}
                  </label>
                  <div class="col">
                    <div class="input-group">
                      <.input
                        field={f[:upload_url]}
                        type="url"
                        class_wrapper="flex-grow"
                        disabled={!@test_updatable}
                      />
                      <div class="input-group-text">
                        <i
                          class="bi bi-info-circle text-body-secondary"
                          data-bs-toggle="tooltip"
                          data-bs-placement="left"
                          title={
                            dgettext(
                              "site",
                              "The file will be downloaded once you submit, not served from the original url"
                            )
                          }
                        >
                        </i>
                      </div>
                    </div>
                  </div>
                  <div class="col-sm-2">
                    <button
                      type="button"
                      class={[
                        "btn",
                        "btn-secondary",
                        "mt-2",
                        "mt-sm-0",
                        (get_field(@changeset, :upload_url) == nil or
                           get_field(@changeset, :upload_url) == "") && "disabled"
                      ]}
                      phx-click="add_url"
                    >
                      <i class="bi bi-plus-lg"></i> {dgettext("test", "Add")}
                    </button>
                  </div>
                </div>
              </div>
            </fieldset>
          </div>
        </div>

        <div
          :if={
            get_field(@changeset, :type) != :listening and
              track_count(@changeset) > 0
          }
          class="alert alert-warning alert-thin"
        >
          <i class="bi bi-info-circle"></i>&nbsp;&nbsp; {raw(
            dgettext(
              "test",
              "Please use descriptive names to have relevant results for visitors. Tracks are <u>anonymized</u> and <u>randomized</u> on the test page (as seen on the <a target=\"_blank\" href=\"/test/demo\">demo</a>)."
            )
          )}
        </div>

        <div
          :if={
            get_field(@changeset, :type) == "listening" and get_field(@changeset, :public) == true and
              track_count(@changeset) > 0
          }
          class="alert alert-warning alert-thin"
        >
          <i class="bi bi-info-circle"></i>&nbsp;&nbsp; {raw(
            dgettext("test", "Please use descriptive names.")
          )}
        </div>

        {error_tag(f, :tracks)}

        <fieldset>
          <div class={["mb-2 py-1 rounded-3 form-unit", track_count(@changeset) === 0 && "d-none"]}>
            <.inputs_for :let={fp} field={f[:tracks]}>
              <%= if input_value(fp, :id) != nil do %>
                <input
                  type="hidden"
                  id={input_id(fp, :id)}
                  name={input_name(fp, :id)}
                  value={input_value(fp, :id)}
                />

                <input
                  type="hidden"
                  id={input_id(fp, :delete)}
                  name={input_name(fp, :delete)}
                  value={input_value(fp, :delete)}
                />
              <% else %>
                <input
                  type="hidden"
                  id={input_id(fp, :temp_id)}
                  name={input_name(fp, :temp_id)}
                  value={input_value(fp, :temp_id)}
                />
              <% end %>

              <%= if input_value(fp, :url) != nil do %>
                <input
                  type="hidden"
                  id={input_id(fp, :url)}
                  name={input_name(fp, :url)}
                  value={input_value(fp, :url)}
                />
              <% end %>

              <input
                type="hidden"
                id={input_id(fp, :original_filename)}
                name={input_name(fp, :original_filename)}
                value={input_value(fp, :original_filename)}
              />

              <input
                type="hidden"
                id={input_id(fp, :filename)}
                name={input_name(fp, :filename)}
                value={input_value(fp, :filename)}
              />

              <%= unless Enum.member?(@tracks_to_delete, input_value(fp, :id)) == true do %>
                <div class={["row p-2 mx-0", input_value(fp, :id) != nil && " mb-2"]}>
                  <label class="col-sm-1 col-form-label">
                    {dgettext("test", "Track #%{track_index}", track_index: fp.index + 1)}
                  </label>
                  <hr class="d-block d-sm-none mb-0" />
                  <label class="col-sm-1 col-form-label text-start text-md-end">
                    {dgettext("test", "Name:*")}
                  </label>
                  <div class="col-sm-4">
                    <.input
                      field={fp[:title]}
                      type="text"
                      required
                    />
                  </div>
                  <%= if get_upload_entry(input_value(fp, :temp_id), @uploads.tracks.entries) != nil and get_upload_entry_progress(input_value(fp, :temp_id), @uploads.tracks.entries) > 0 do %>
                    <label class="col-sm-1 col-form-label text-start text-md-end mt-2 mt-md-0">
                      {dgettext("test", "Upload")}
                    </label>
                    <div class="col d-flex align-items-center">
                      <progress
                        value={
                          get_upload_entry_progress(
                            input_value(fp, :temp_id),
                            @uploads.tracks.entries
                          )
                        }
                        max="100"
                      >
                        {get_upload_entry_progress(
                          input_value(fp, :temp_id),
                          @uploads.tracks.entries
                        )}%
                      </progress>
                    </div>
                  <% else %>
                    <label class="col-sm-1 col-form-label text-start text-md-end mt-2 mt-md-0">
                      {dgettext("test", "File:")}
                    </label>
                    <div
                      class="col w-100 text-truncate d-flex align-items-center"
                      title={input_value(fp, :original_filename)}
                    >
                      {input_value(fp, :original_filename)}
                    </div>
                  <% end %>
                  <div class="col-sm-2 d-flex flex-row-reverse" style="min-width: 62px">
                    <%= if input_value(fp, :id) != nil do %>
                      <button
                        type="button"
                        class={[
                          "btn",
                          "btn-dark",
                          @test_updatable == false && " disabled"
                        ]}
                        data-confirm={dgettext("site", "Are you sure?")}
                        phx-click="delete_track"
                        phx-value-id={input_value(fp, :id)}
                      >
                        <i class="bi bi-trash text-danger"></i>
                      </button>
                    <% else %>
                      <button
                        type="button"
                        class={[
                          "btn",
                          "btn-dark",
                          @test_updatable == false && " disabled"
                        ]}
                        phx-click="remove_track"
                        phx-value-id={input_value(fp, :temp_id)}
                      >
                        <i class="bi bi-trash text-danger"></i>
                      </button>
                    <% end %>

                    <label
                      :if={Tests.can_have_reference_track?(@changeset)}
                      class="col-form-label pe-3"
                    >
                      <.input
                        field={fp[:reference_track]}
                        type="checkbox"
                      />&nbsp;&nbsp;{dgettext(
                        "test",
                        "Reference"
                      )} &nbsp;<i
                        class="bi bi-info-circle text-body-secondary"
                        data-bs-toggle="tooltip"
                        title={
                          dgettext(
                            "site",
                            "Reference / unprocessed track that will not be part of the test but playable alongside the others."
                          )
                        }
                      >
                      </i>
                    </label>
                  </div>
                </div>
              <% end %>
            </.inputs_for>
          </div>
        </fieldset>

        <div class="mt-2 text-center text-md-end d-flex flex-row justify-content-end align-items-center">
          <div class="pe-2">{error_tag(f, :type)}</div>
          <div
            class="loading-spinner spinner-border spinner-border-sm text-primary me-2"
            role="status"
          >
            <span class="visually-hidden">{dgettext("test", "Loading...")}</span>
          </div>
          <%= if @action == "save" do %>
            <button
              type="submit"
              class="btn btn-lg btn-primary"
              phx-disable-with="Saving..."
              disabled={!@changeset.valid? or @test_submittable == false}
            >
              {dgettext("test", "Save test")}
            </button>
          <% else %>
            <button
              type="submit"
              class="btn btn-lg btn-primary"
              phx-disable-with={dgettext("site", "Updating ...")}
              disabled={!@changeset.valid? or @test_submittable == false}
            >
              {dgettext("test", "Update test")}
            </button>
          <% end %>
        </div>
      </.form>

      <.live_component
        module={BsModalComponent}
        id="email-modal"
        title={dgettext("site", "Send an invitation")}
      >
        <.live_component
          id="email-modal-comp"
          module={InvitationComponent}
          test={@test}
          user={@current_user}
        />
      </.live_component>
    </Layouts.app>
    """
  end

  # ---------- MOUNT ----------

  # Edit
  @impl true
  def mount(%{"slug" => slug} = params, session, socket) do
    with test when not is_nil(test) <- Tests.get_edit(slug),
         nil <- test.deleted_at,
         true <-
           (params["key"] != nil and params["key"] == test.access_key) or
             Map.get(socket.assigns, :current_scope, %{}) |> Map.get(:user, %{}) |> Map.get(:id) ==
               test.user_id do
      test_updatable = !Tests.has_tests_taken?(test)
      changeset = Test.changeset_update(test)

      if connected?(socket) do
        FunkyABXWeb.Endpoint.subscribe(test.id)
        Tests.update_last_viewed(test)
      end

      {:ok,
       socket
       |> assign_new(:current_user, fn ->
         case session["user_token"] do
           nil ->
             nil

           token ->
             {user, _inserted_at} = Accounts.get_user_by_session_token(token)
             user
         end
       end)
       |> assign(%{
         page_title:
           dgettext("test", "Edit test - %{title}",
             title: String.slice(test.title, 0..@title_max_length)
           ),
         action: "update",
         current_user: test.user,
         changeset: changeset,
         test: Map.put(test, :to_close_at_timezone, get_timezone(socket)),
         tracks_to_delete: [],
         test_updatable: test_updatable,
         test_submittable: true
       })
       |> allow_upload(:tracks,
         accept: ~w(.wav .mp3 .aac .flac),
         max_entries: 20,
         max_file_size: 500_000_000
       )}
    else
      _ ->
        {:ok,
         socket
         |> put_flash(
           :error,
           dgettext("test", "Test authentication failed. Please log in or check your link.")
         )
         |> redirect(to: ~p"/test")}
    end
  end

  # New
  @impl true
  def mount(params, session, socket) do
    user =
      case session["user_token"] do
        nil ->
          nil

        token ->
          {user, _inserted_at} = Accounts.get_user_by_session_token(token)
          user
      end

    access_key = if user == nil, do: UUID.generate(), else: nil
    name = Map.get(session, "author")

    test =
      Test.new(%{
        user: user,
        access_key: access_key,
        author: name,
        ip_address: Map.get(session, "visitor_ip", nil),
        to_close_at_timezone: get_timezone(socket)
      })

    changeset =
      Test.changeset(
        test,
        Map.merge(
          %{},
          Tests.form_data_from_session(session)
          |> Tests.form_data_from_params(params)
        )
      )

    {:ok,
     socket
     |> assign(%{
       page_title: dgettext("test", "Create test"),
       action: "save",
       current_user: user,
       changeset: changeset,
       test: test,
       tracks_to_delete: [],
       test_updatable: true,
       test_submittable: true
     })
     |> allow_upload(:tracks,
       accept: ~w(.wav .mp3 .aac .flac),
       max_entries: 20,
       max_file_size: 500_000_000
     )}
  end

  # ---------- PUB/SUB EVENTS ----------

  @impl true
  def handle_info(%{event: "test_taken"} = _payload, socket) do
    test = Tests.get(socket.assigns.test.id)

    # We update the assigns of the modal component
    # to avoid destroying the hook which manages the boostrap modal
    send_update(InvitationComponent, id: "email-modal-comp", test: test)

    {:noreply,
     socket
     |> put_flash(:success, dgettext("test", "Someone just took this test!"))}
  end

  @impl true
  def handle_info(%{event: "comment_posted"} = _payload, socket) do
    test = Tests.get(socket.assigns.test.id)

    {:noreply,
     socket
     |> put_flash(:success, dgettext("test", "Someone just commented on this test!"))}
  end

  @impl true
  def handle_info(%{event: "invitation_viewed"} = _payload, socket) do
    test = Tests.get(socket.assigns.test.id)

    # We update the assigns of the modal component
    # to avoid destroying the hook which manages the boostrap modal
    send_update(InvitationComponent, id: "email-modal-comp", test: test)

    {:noreply,
     socket
     |> put_flash(:success, dgettext("test", "The test has been opened from an invitation."))}
  end

  def handle_info(:invitations_updated, socket) do
    test =
      socket.assigns.test
      |> Repo.preload([:invitations], force: true)

    # We update the assigns of the modal component
    # to avoid destroying the hook which manages the boostrap modal
    send_update(InvitationComponent, id: "email-modal-comp", test: test)

    {:noreply, socket}
  end

  def handle_info(%{event: _event} = _payload, socket) do
    {:noreply, socket}
  end

  # ---------- INDIRECT FORM EVENTS ----------

  def handle_info({:update, %{"test" => test_params}}, socket) do
    updated_test_params = consume_and_update_form_tracks_params(test_params, socket)

    update_changeset = Test.changeset_update(socket.assigns.changeset, updated_test_params)
    update = Repo.update(update_changeset)

    case update do
      {:ok, test} ->
        Logger.info("Test updated")

        FunkyABXWeb.Endpoint.broadcast!(socket.assigns.test.id, "test_updated", nil)

        if Ecto.Changeset.fetch_change(update_changeset, :to_close_at_enabled) !== :error or
             Ecto.Changeset.fetch_change(update_changeset, :to_close_at) !== :error do
          case test.to_close_at_enabled do
            true -> TestClosingWorker.insert_test_to_closing_queue(test)
            false -> TestClosingWorker.remove_test_from_closing_queue(test)
          end
        end

        # Delete files from removed tracks
        socket.assigns.test.tracks
        |> Enum.filter(fn t -> t.id in socket.assigns.tracks_to_delete end)
        |> Enum.map(fn t -> t.filename end)
        |> Files.delete(socket.assigns.test.id)

        test = Tests.get_edit(test.slug)
        changeset = Test.changeset_update(test)

        {:noreply,
         socket
         |> assign(test: test, changeset: changeset, test_submittable: true)
         |> put_flash(:success, dgettext("test", "Your test has been successfully updated!"))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset, tracks_to_delete: [])}
    end
  end

  def handle_info({:save, %{"test" => test_params}}, socket) do
    updated_test_params = consume_and_update_form_tracks_params(test_params, socket)

    insert =
      socket.assigns.test
      |> Test.changeset(updated_test_params)
      |> Repo.insert()

    case insert do
      {:ok, test} ->
        if test.to_close_at_enabled == true,
          do: TestClosingWorker.insert_test_to_closing_queue(test)

        # logged or not
        redirect =
          if test.user != nil do
            ~p"/edit/#{test.slug}"
          else
            ~p"/edit/#{test.slug}/#{test.access_key}"
          end

        #        Process.send_after(
        #          self(),
        #          {:redirect, redirect <> "#top"},
        #          1500
        #        )

        changeset = Test.changeset_update(test)

        Logger.info("Test created (#{test.slug} / #{test.type} / #{length(test.tracks)} tracks)")

        {
          :noreply,
          socket
          |> assign(action: "update", test: test, changeset: changeset)
          |> push_event("saveTest", %{
            test_id: test.id,
            test_access_key: test.access_key,
            test_author: test.author
          })
          |> push_event("store_params", %{
            "params" => [
              %{
                "name" => "identification",
                "value" => test_params["identification"]
              },
              %{
                "name" => "rating",
                "value" => test_params["rating"]
              },
              %{
                "name" => "regular_type",
                "value" => test_params["regular_type"]
              }
            ]
          })
          |> put_flash(:success, dgettext("test", "Your test has been successfully created!"))
          |> redirect(to: "#{redirect}#top")
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.warning(
          "Test creating failed (#{fetch_field!(changeset, :type)} / #{length(fetch_field!(changeset, :tracks))} tracks)"
        )

        {:noreply,
         socket
         |> Utils.send_error_toast()
         |> assign(changeset: changeset)}
    end
  end

  # ---------- MISC EVENTS ----------

  @impl true
  def handle_event("clipboard", %{"text" => text}, socket) do
    {:noreply,
     socket
     |> put_flash(:success, dgettext("test", "Copied to clipboard"))
     |> push_event("clipboard", %{text: text})}
  end

  # ---------- FORM EVENTS ----------

  @impl true
  def handle_event("validate", %{"test" => test_params, "_target" => target}, socket) do
    updated_test_params =
      target
      |> List.last()
      |> FormUtils.update_test_params(test_params)
      |> FormUtils.update_reference_track_params(target)
      |> build_upload_tracks(socket)

    changeset =
      socket.assigns.test
      |> Test.changeset_update(updated_test_params)
      |> update_action(socket.assigns.action)

    {:noreply,
     assign(socket,
       changeset: changeset,
       upload_url: test_params["upload_url"]
     )}
  end

  # Edit

  @impl true
  def handle_event("update", _params, socket) when socket.assigns.test_submittable == false do
    {:noreply, socket}
  end

  @impl true
  def handle_event("update", params, socket) do
    send(self(), {:update, params})
    {:noreply, assign(socket, test_submittable: false)}
  end

  # New

  @impl true
  def handle_event("save", _params, socket) when socket.assigns.test_submittable == false do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", params, socket) do
    send(self(), {:save, params})
    {:noreply, assign(socket, test_submittable: false)}
  end

  @impl true
  def handle_event("close_test", _params, socket) do
    test =
      socket.assigns.test
      |> Repo.preload(:user)

    test
    |> Test.changeset_close()
    |> Repo.update()

    # update data
    test = Tests.get_edit(test.slug)

    case Tests.is_closed?(test) do
      false -> FunkyABXWeb.Endpoint.broadcast!(test.id, "test_opened", nil)
      true -> FunkyABXWeb.Endpoint.broadcast!(test.id, "test_closed", nil)
    end

    changeset = Test.changeset_update(test)

    {:noreply,
     socket
     |> put_flash(:success, dgettext("test", "Your test has been successfully updated."))
     |> assign(test: test, changeset: changeset, test_submittable: true)}
  end

  @impl true
  def handle_event("delete_test", _params, socket) do
    test =
      socket.assigns.test
      |> Repo.preload(:user)

    Files.delete_all(test.id)

    test
    |> Test.changeset_delete()
    |> Repo.update()

    TestClosingWorker.remove_test_from_closing_queue(test)
    FunkyABXWeb.Endpoint.broadcast!(test.id, "test_deleted", nil)

    Logger.info("Test deleted (#{test.slug})")

    {
      :noreply,
      socket
      |> push_event("deleteTest", %{
        test_id: test.id,
        test_access_key: test.access_key
      })
      |> put_flash(:success, dgettext("test", "Your test has been successfully deleted."))
      |> redirect(to: ~p"/info")
    }
  end

  @impl true
  def handle_event(
        "track_file_selected",
        %{"track_id" => track_id, "filename" => filename},
        socket
      ) do
    {:noreply, set_track_title_if_empty(socket, track_id, filename)}
  end

  # ---------- TRACKS ----------

  @impl true
  def handle_event("add_url", _value, socket)
      when socket.assigns.test_updatable == true and is_binary(socket.assigns.upload_url) and
             socket.assigns.upload_url != "" do
    {:noreply, add_url_maybe(socket, socket.assigns.upload_url)}
  end

  @impl true
  def handle_event("add_url", _value, socket) do
    {:noreply, socket}
  end

  # Persisted tracks

  @impl true
  def handle_event("delete_track", _params, socket) when socket.assigns.test_updatable == false do
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete_track", %{"id" => track_id}, socket) do
    tracks =
      socket.assigns.changeset
      |> get_field(:tracks)
      |> Enum.map(fn t ->
        case t.id == track_id do
          true ->
            Track.changeset(t, %{delete: true})

          false ->
            Track.changeset(t, %{})
        end
      end)

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_assoc(:tracks, tracks)

    updated_tracks_to_delete = socket.assigns.tracks_to_delete ++ [track_id]

    {:noreply,
     socket
     |> assign(%{changeset: changeset, tracks_to_delete: updated_tracks_to_delete})
     |> push_event("revalidate", %{})}
  end

  # New tracks

  @impl true
  def handle_event("remove_track", _params, socket) when socket.assigns.test_updatable == false do
    {:noreply, socket}
  end

  @impl true
  def handle_event("remove_track", %{"id" => track_id}, socket) do
    tracks =
      socket.assigns.changeset.changes.tracks
      |> Enum.reject(fn %{data: track} ->
        track.temp_id == track_id
      end)

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_assoc(:tracks, tracks)

    {:noreply,
     socket
     |> assign(%{changeset: changeset})
     |> then(fn socket ->
       # only cancel upload if entry is not from url
       case get_upload_entry(track_id, socket.assigns.uploads.tracks.entries) do
         nil ->
           socket

         entry ->
           ref_to_cancel = Map.get(entry, :ref)
           cancel_upload(socket, :tracks, ref_to_cancel)
       end
     end)
     |> push_event("revalidate", %{})}
  end

  defp build_upload_tracks(test_params, socket) do
    existing_ids =
      socket.assigns.changeset
      |> get_field(:tracks)
      |> Enum.map(&(&1.id || &1.temp_id))

    new_tracks =
      socket.assigns.uploads.tracks.entries
      |> Enum.reject(fn e -> e.uuid in existing_ids end)
      |> Enum.map(fn e ->
        %{
          "test_id" => socket.assigns.test.id,
          "temp_id" => e.uuid,
          "title" => Tracks.filename_to_title(e.client_name),
          "original_filename" => e.client_name,
          "filename" => e.client_name
        }
      end)

    existing_tracks =
      test_params
      |> Map.get("tracks", [])
      |> Enum.flat_map(fn {_k, t} ->
        case Enum.member?(existing_ids, Map.get(t, "id") || Map.get(t, "temp_id")) do
          true -> [t]
          false -> []
        end
      end)

    Map.put(test_params, "tracks", existing_tracks ++ new_tracks)
  end

  defp add_url_maybe(socket, url) when is_binary(url) do
    parsed_upload_url = Urls.parse_url_tracks(url)

    socket
    |> add_track_from_url(parsed_upload_url)
    |> push_event("revalidate", %{})
  end

  defp add_url_maybe(socket, _url), do: socket

  defp add_track_from_url(socket, url) when is_list(url) do
    Enum.reduce(url, socket, fn x, acc ->
      add_track_from_url(acc, x)
    end)
  end

  defp add_track_from_url(socket, url) do
    temp_id = UUID.generate()

    {title, final_url} =
      case url do
        {file_title, dest_url} ->
          {Tracks.url_to_title(file_title), dest_url}

        _ ->
          {Tracks.url_to_title(url), url}
      end

    tracks =
      socket.assigns.changeset
      |> get_field(:tracks)
      |> Enum.concat([
        Track.changeset(
          %Track{
            test_id: socket.assigns.test.id,
            temp_id: temp_id,
            original_filename: final_url,
            url: final_url,
            title: title
          },
          %{}
        )
      ])

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_assoc(:tracks, tracks)
      |> Test.changeset_reset_upload_url()

    socket
    |> assign(upload_url: nil, changeset: changeset)
  end

  def error_to_string(:too_large), do: dgettext("test", "Too large")
  def error_to_string(:too_many_files), do: dgettext("test", "You have selected too many files")

  def error_to_string(:not_accepted),
    do: dgettext("test", "You have selected an unacceptable file type")

  # ---

  defp set_track_title_if_empty(socket, track_id, filename)
       when is_binary(track_id) and is_binary(filename) do
    tracks =
      socket.assigns.changeset.changes.tracks
      |> Enum.map(fn
        %{changes: changes, data: %{temp_id: temp_id} = track}
        when temp_id == track_id and
               ((is_map_key(changes, :title) and (changes.title == nil or changes.title == "")) or
                  is_map_key(changes, :title) == false) ->
          Track.changeset(track, %{title: Tracks.filename_to_title(filename)})

        track_changeset ->
          track_changeset
      end)

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_assoc(:tracks, tracks)

    assign(socket, %{changeset: changeset})
  end

  # ---------- FORM UTILS ----------

  defp consume_and_update_form_tracks_params(test_params, socket) do
    normalization =
      socket.assigns.test
      |> Test.changeset_update(test_params)
      |> get_field(:normalization)

    updated_tracks =
      test_params
      |> Map.get("tracks", %{})
      # uploads
      |> Enum.reduce(%{}, fn {k, t}, acc ->
        upload_entry = get_upload_entry(t["temp_id"], socket.assigns.uploads.tracks.entries)

        upload_consumed =
          unless upload_entry == nil do
            consume_uploaded_entry(socket, upload_entry, fn %{path: path} ->
              filename_dest = Files.get_destination_filename(upload_entry.client_name)

              final_filename_dest =
                Files.save(
                  path,
                  Path.join([socket.assigns.test.id, filename_dest]),
                  [],
                  normalization
                )

              {:ok, {upload_entry.client_name, final_filename_dest}}
            end)
          else
            nil
          end

        case upload_consumed do
          {original_filename, filename} ->
            updated_track =
              Map.merge(t, %{"filename" => filename, "original_filename" => original_filename})

            Map.put(acc, k, updated_track)

          _ ->
            Map.put(acc, k, t)
        end
      end)
      # url download
      |> Enum.reduce(%{}, fn {k, t}, acc ->
        with false <- Map.has_key?(t, "id"),
             url when url != nil <- Map.get(t, "url"),
             downloaded when downloaded != :error <-
               Tracks.import_track_url(t, socket.assigns.test.id, normalization) do
          Map.put(acc, k, downloaded)
        else
          :error ->
            #            Utils.send_error_toast(
            #              "Error downloading #{t["original_filename"]}",
            #              socket.assigns.page_id
            #            )

            Map.put(acc, k, t)

          _ ->
            Map.put(acc, k, t)
        end
      end)

    Map.put(test_params, "tracks", updated_tracks)
  end

  defp update_action(changeset, "update") do
    Map.put(changeset, :action, :update)
  end

  defp update_action(changeset, _action) do
    #    Map.put(:action, :insert)
    changeset
  end

  defp get_upload_entry(track_id, uploads) do
    Enum.find(uploads, &(&1.uuid == track_id))
  end

  defp get_upload_entry_progress(track_id, uploads) do
    case get_upload_entry(track_id, uploads) do
      nil -> nil
      entry -> entry.progress
    end
  end

  defp get_timezone(socket) do
    case get_connect_params(socket) do
      nil -> "Etc/UTC"
      params -> Map.get(params, "timezone", "Etc/UTC")
    end
  end

  defp track_count(changeset) do
    changeset
    |> get_field(:tracks)
    |> Enum.reject(&(&1.delete == true))
    |> Kernel.length()
  end
end
