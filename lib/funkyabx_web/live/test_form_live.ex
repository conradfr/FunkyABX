defmodule FunkyABXWeb.TestFormLive do
  import Ecto.Changeset
  require Logger
  use FunkyABXWeb, :live_view

  alias Ecto.UUID
  alias Phoenix.LiveView.JS
  alias FunkyABX.Repo

  alias FunkyABX.Tests.FormUtils
  alias FunkyABX.{Accounts, Utils, Urls, Tests, Files, Tracks, TestClosing}
  alias FunkyABX.{Test, Track}

  @title_max_length 100

  @impl true
  def render(assigns) do
    ~H"""
    <.form
      :let={f}
      class="mb-2"
      for={@changeset}
      phx-change="validate"
      phx-submit={@action}
      id="test-form"
      phx-hook="TestForm"
    >
      <%= hidden_input(f, :access_key) %>
      <div class="row">
        <div class="col-md-6 col-sm-12 order-md-1 order-2">
          <h3 class="mb-2 mt-0 header-chemyretro">
            <%= if @action == "save" do %>
              <%= dgettext("test", "Create a new test") %>
            <% else %>
              <%= dgettext("test", "Edit a test") %>
            <% end %>
          </h3>

          <%= if @action == "save" do %>
            <div class="alert alert-info alert-thin">
              <i class="bi bi-info-circle"></i>&nbsp;&nbsp;<%= raw(
                dgettext(
                  "test",
                  "If you're making a one-off test for yourself, consider making a <a href=\"%{link}\">local test</a>, it's quicker and avoids uploading your files.",
                  link: ~p"/local_test"
                )
              ) %>
            </div>
          <% end %>

          <fieldset class="form-group mb-3">
            <legend class="mt-1 header-typographica"><%= dgettext("test", "Test type") %></legend>
            <%= if @test_updatable == false do %>
              <div class="alert alert-warning alert-thin">
                <i class="bi bi-x-circle"></i>&nbsp;&nbsp;<%= dgettext(
                  "test",
                  "Test type can't be changed once at least one person has taken the test."
                ) %>
              </div>
            <% end %>
            <div class="form-unit px-3 py-3 rounded-3">
              <div class="form-check">
                <label class="form-check-label">
                  <%= radio_button(f, :type, "regular",
                    class: "form-check-input",
                    disabled: !@test_updatable
                  ) %>
                  <%= dgettext("test", "Blind test") %>
                </label>
                <%= error_tag(f, :type) %>
              </div>
              <div class="fs-8 mb-2 text-body-secondary ms-4 mb-1">
                <i class="bi bi-info-circle"></i>&nbsp;&nbsp;Select at least one option
              </div>
              <div class="form-check ms-4">
                <label class="form-check-label">
                  <%= checkbox(f, :rating,
                    class: "form-check-input",
                    disabled: !@test_updatable or get_field(@changeset, :type) !== :regular
                  ) %>
                  <%= dgettext("test", "Enable rating") %>
                </label>

                <div class="form-check mt-2 ms-1 form-test-example" data-target="example-picking">
                  <label class="form-check-label">
                    <%= radio_button(f, :regular_type, "pick",
                      class: "form-check-input",
                      disabled:
                        !@test_updatable or get_field(@changeset, :type) !== :regular or
                          get_field(@changeset, :rating) !== true
                    ) %> Picking
                  </label>
                  <div class="form-text mb-2">
                    <%= dgettext("test", "People will have to pick their preferred track") %>
                  </div>
                </div>

                <div class="form-check ms-1 form-test-example" data-target="example-stars">
                  <label class="form-check-label">
                    <%= radio_button(f, :regular_type, "star",
                      class: "form-check-input",
                      disabled:
                        !@test_updatable or get_field(@changeset, :type) !== :regular or
                          get_field(@changeset, :rating) !== true
                    ) %> Stars
                  </label>
                  <div class="form-text mb-2">
                    <%= dgettext(
                      "test",
                      "Each track will have a 1-5 star rating (usually NOT the best choice !)"
                    ) %>
                  </div>
                </div>

                <div class="form-check ms-1 form-test-example" data-target="example-ranking">
                  <label class="form-check-label">
                    <%= radio_button(f, :regular_type, "rank",
                      class: "form-check-input",
                      disabled:
                        !@test_updatable or get_field(@changeset, :type) !== :regular or
                          get_field(@changeset, :rating) !== true
                    ) %>
                    <%= dgettext("test", "Ranking") %>
                  </label>
                  <div class="form-text mb-2">
                    <%= dgettext("test", "People will be asked to rank the tracks") %>
                  </div>
                  <div class="form-check ms-4">
                    <label class="form-check-label">
                      <%= checkbox(f, :ranking_only_extremities,
                        class: "form-check-input",
                        disabled:
                          !@test_updatable or get_field(@changeset, :type) !== :regular or
                            Kernel.length(get_field(@changeset, :tracks)) < 10
                      ) %>
                      <%= dgettext("test", "Only rank the top/bottom three tracks") %>
                    </label>
                    <div class="form-text mb-2">
                      <%= dgettext("test", "Only for tests with 10+ tracks") %>
                    </div>
                  </div>
                </div>
              </div>
              <div class="form-check ms-4 form-test-example" data-target="example-identification">
                <label class="form-check-label">
                  <%= checkbox(f, :identification,
                    class: "form-check-input",
                    disabled: !@test_updatable or get_field(@changeset, :type) !== :regular
                  ) %>
                  <%= dgettext("test", "Recognition test") %>
                </label>
                <div class="form-text mb-2">
                  <%= dgettext("test", "People will have to identify the anonymized tracks") %>
                </div>
              </div>

              <div class="form-check disabled mt-4 mb-2 form-test-example" data-target="example-abx">
                <label class="form-check-label">
                  <%= radio_button(f, :type, "abx",
                    class: "form-check-input",
                    disabled: !@test_updatable
                  ) %>
                  <%= dgettext("test", "ABX test") %>
                </label>
                <div class="form-text mb-2">
                  <%= dgettext("test", "People will have to guess which track is cloned for n rounds") %>
                </div>
                <div class="row ms-4 mb-1">
                  <label for="test[nb_of_rounds]" class="col-6 col-sm-4 col-form-label ps-0">
                    <%= dgettext("test", "Number of rounds:") %>
                  </label>
                  <div class="col-6 col-sm-2">
                    <%= number_input(f, :nb_of_rounds,
                      class: "form-control",
                      required: input_value(f, :type) == :abx,
                      disabled: !@test_updatable or get_field(@changeset, :type) !== :abx
                    ) %>
                  </div>
                </div>
                <div class="form-check mt-2 ms-4 mb-3">
                  <label class="form-check-label">
                    <%= checkbox(f, :anonymized_track_title,
                      class: "form-check-input",
                      disabled: !@test_updatable or get_field(@changeset, :type) !== :abx
                    ) %>
                    <%= dgettext("test", "Hide tracks' title") %>
                  </label>
                </div>
              </div>

              <div class="form-check disabled mt-4">
                <label class="form-check-label">
                  <%= radio_button(f, :type, "listening",
                    class: "form-check-input",
                    disabled: !@test_updatable
                  ) %>
                  <%= dgettext("test", "No test, only listening") %>
                </label>
              </div>
            </div>
          </fieldset>
        </div>

        <div class="offset-md-1 col-md-5 col-m-12 order-1 order-md-2">
          <%= if @action == "update" do %>
            <fieldset class="form-group mb-3">
              <%= unless @test.view_count == nil do %>
                <legend class="header-typographica">
                  <div
                    class="float-end fs-8 text-body-secondary"
                    style="font-family: var(--bs-font-sans-serif); padding-top: 12px;"
                  >
                    <%= raw(
                      dngettext(
                        "test",
                        "Viewed <strong>%{count}</strong> time",
                        "Viewed <strong>%{count}</strong> times",
                        @test.view_count
                      )
                    ) %>
                  </div>
                  <%= dgettext("test", "Your test") %>
                </legend>
              <% end %>
              <div class="px-3 pt-2 pb-3 rounded-3" style="background-color: #583247;">
                <div class="mb-3">
                  <label for="test_public_link" class="form-label w-100">
                    <div class="float-end">
                      <%= checkbox(f, :embed, class: "form-check-input") %>&nbsp;&nbsp;Embed
                    </div>
                    <%= dgettext("test", "Test public page") %>
                    <span class="form-text"><%= dgettext("test", "(share this link)") %></span>
                  </label>
                  <% test_url =
                    if input_value(f, :embed) == "true" do
                      url(~p"/test/#{input_value(f, :slug)}?embed=1")
                    else
                      url(~p"/test/#{input_value(f, :slug)}")
                    end %>
                  <div class="input-group mb-3">
                    <%= text_input(f, :public_link,
                      class: "form-control",
                      readonly: "readonly",
                      value: test_url
                    ) %>
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
                    <%= dgettext("test", "Test edit page") %>
                    <span class="form-text"><%= dgettext("test", "(this page)") %></span>
                  </label>
                  <div class="input-group mb-3">
                    <%= if @current_user do %>
                      <%= text_input(f, :edit_link,
                        class: "form-control",
                        readonly: "readonly",
                        value: url(~p"/edit/#{input_value(f, :slug)}")
                      ) %>
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
                      <%= text_input(f, :edit_link,
                        class: "form-control",
                        readonly: "readonly",
                        value: url(~p"/edit/#{input_value(f, :slug)}/#{input_value(f, :access_key)}")
                      ) %>
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
                        href={url(~p"/edit/#{input_value(f, :slug)}/#{input_value(f, :access_key)}")}
                      >
                        <i class="bi bi-box-arrow-up-right"></i>
                      </a>
                    <% end %>
                  </div>
                </div>
                <%= unless get_field(@changeset, :type) == :listening or get_field(@changeset, :hide_global_results) == true do %>
                  <div class="mb-3">
                    <label for="" class="form-label">
                      <%= dgettext("test", "Test private results page") %>
                      <span class="form-text">
                        <%= dgettext("test", "(if you don't take the test)") %>
                      </span>
                    </label>
                    <div class="input-group mb-3">
                      <%= if @current_user do %>
                        <%= text_input(f, :results_link,
                          class: "form-control",
                          readonly: "readonly",
                          value: url(~p"/results/#{input_value(f, :slug)}")
                        ) %>
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
                        <%= text_input(f, :results_link,
                          class: "form-control",
                          readonly: "readonly",
                          value:
                            url(~p"/results/#{input_value(f, :slug)}/#{input_value(f, :access_key)}")
                        ) %>
                        <button
                          class="btn btn-info"
                          type="button"
                          title={dgettext("site", "Copy to clipboard")}
                          phx-click="clipboard"
                          phx-value-text={
                            url(~p"/results/#{input_value(f, :slug)}/#{input_value(f, :access_key)}")
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
                            url(~p"/results/#{input_value(f, :slug)}/#{input_value(f, :access_key)}")
                          }
                        >
                          <i class="bi bi-box-arrow-up-right"></i>
                        </a>
                      <% end %>
                    </div>
                  </div>
                <% end %>
                <div class="text-center">
                  <hr />
                  <div class="d-flex justify-content-evenly">
                    <button
                      :if={@test.type !== :listening and Tests.is_closed?(@test) == false}
                      type="button"
                      class="btn btn-info"
                      data-confirm={dgettext("site", "Are you sure?")}
                      phx-click="close_test"
                    >
                      <i class="bi bi-x-circle"></i>&nbsp;&nbsp;<%= dgettext("test", "Close the test") %>
                    </button>
                    <button
                      :if={Tests.is_closed?(@test)}
                      type="button"
                      class="btn btn-warning"
                      data-confirm="Are you sure?"
                      phx-click="close_test"
                    >
                      <i class="bi bi-check-circle"></i> <%= dgettext("test", "Reopen the test") %>
                    </button>
                    <button
                      type="button"
                      class="btn btn-danger"
                      data-confirm={dgettext("site", "Are you sure?")}
                      phx-click="delete_test"
                    >
                      <i class="bi bi-trash"></i>&nbsp;&nbsp;<%= dgettext("test", "Delete the test") %>
                    </button>
                  </div>
                </div>
              </div>
            </fieldset>
            <div class="text-center mb-4">
              <%= if @current_user == nil do %>
                <span class="text-body-secondary">
                  <i class="bi bi-envelope"></i> <%= dgettext("test", "Send invitations") %>
                </span>
                <span :if={@current_user == nil} class="text-body-secondary">
                  <br />
                  <small>
                    &nbsp;<%= dgettext(
                      "test",
                      "(available only for tests created by logged in users)"
                    ) %>
                  </small>
                </span>
              <% else %>
                <a
                  href="#"
                  class="link-no-decoration"
                  phx-click={JS.dispatch("open_modal", to: "body")}
                >
                  <i class="bi bi-envelope"></i> <%= dgettext("test", "Send invitations") %>
                </a>
              <% end %>
            </div>
          <% else %>
            <div class="w-100 text-center d-none d-sm-block" style="padding-top: 200px;">
              <div class="form-example rounded-1 d-none" id="example-picking">
                <img
                  title={dgettext("site", "Picking example")}
                  src={~p"/images/example-picking.png"}
                />
              </div>
              <div class="form-example rounded-1 d-none" id="example-stars">
                <img title={dgettext("site", "Stars example")} src={~p"/images/example-stars.png"} />
              </div>
              <div class="form-example rounded-1 d-none" id="example-ranking">
                <img
                  title={dgettext("site", "Ranking example")}
                  src={~p"/images/example-ranking.png"}
                />
              </div>
              <div class="form-example rounded-1 d-none" id="example-identification">
                <img
                  title={dgettext("site", "Identification example")}
                  src={~p"/images/example-identification.png"}
                />
              </div>
              <div class="form-example rounded-1 d-none" id="example-abx">
                <img title={dgettext("site", "Abx example")} src={~p"/images/example-abx.png"} />
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <fieldset class="form-group mb-3">
        <legend class="mt-1 header-typographica"><%= dgettext("test", "Infos") %></legend>
        <div class="form-unit p-3 pb-2 rounded-3">
          <div class="row mb-3">
            <div class="col-12 col-md-6">
              <%= label(:f, :title, dgettext("test", "Title*"), class: "form-label") %>
              <%= text_input(f, :title,
                class: "form-control",
                placeholder: "Mandatory",
                required: true
              ) %>
              <%= error_tag(f, :title) %>
            </div>
            <div class="col-12 col-md-6 pt-3 pt-md-0">
              <%= label(:f, :author, dgettext("test", "Created by"), class: "form-label") %>
              <%= text_input(f, :author,
                class: "form-control",
                placeholder: dgettext("test", "Optional")
              ) %>
            </div>
          </div>
          <div class="mb-2">
            <%= label :f, :description, class: "form-label w-100" do %>
              <div class="form-check ms-4 float-end">
                <label class="form-check-label">
                  <%= checkbox(f, :description_markdown, class: "form-check-input") %> Use <a
                    target="_blank"
                    href="https://www.markdownguide.org/cheat-sheet/"
                  ><%= dgettext "test", "Markdown" %></a>&nbsp;&nbsp;<small><i
                      class="bi bi-info-circle text-body-secondary"
                      data-bs-toggle="tooltip"
                      data-bs-placement="left"
                      title={dgettext("site", "<br> supported for line breaks")}
                    ></i></small>
                </label>
              </div>
              Description
            <% end %>
            <%= textarea(f, :description,
              class: "form-control",
              rows: "5",
              placeholder: dgettext("test", "Optional")
            ) %>
            <div class="fs-8 mt-2 mb-1 cursor-link" phx-click="toggle_description">
              Preview&nbsp;&nbsp;<i class={[
                "bi",
                @view_description == true && "bi-arrow-down",
                @view_description == false && "bi-arrow-right"
              ]}></i>
            </div>
            <%= if @view_description == true do %>
              <TestDescriptionComponent.format
                description_markdown={get_field(@changeset, :description_markdown)}
                description={get_field(@changeset, :description)}
              />
            <% end %>
          </div>
        </div>
      </fieldset>

      <fieldset class="form-group mb-3">
        <legend class="mt-1 header-typographica"><%= dgettext("test", "Options") %></legend>
        <div class="form-unit p-3 rounded-3">
          <div class="row mb-4">
            <div class="col-12 col-md-6">
              <div class="form-check">
                <label class="form-check-label">
                  <%= checkbox(f, :public, class: "form-check-input") %> &nbsp;&nbsp;<%= dgettext(
                    "test",
                    "The test is public"
                  ) %>
                </label>
                <div class="form-text">
                  <%= dgettext(
                    "test",
                    "It will be published in the gallery 15 minutes after its creation"
                  ) %>
                </div>
              </div>
            </div>
            <div class="col-12 col-md-6 pt-3 pt-md-0">
              <div class="form-check">
                <label class="form-check-label">
                  <%= checkbox(f, :hide_global_results, class: "form-check-input") %> &nbsp;&nbsp;<%= dgettext(
                    "test",
                    "Visitors can only see their own test results."
                  ) %>
                </label>
                <div class="form-text">
                  <%= dgettext(
                    "test",
                    "Global results and stats of the test will be hidden (even for you)"
                  ) %>
                </div>
              </div>
            </div>
          </div>
          <div class="row mb-4">
            <div class="col-12 col-md-6 pt-3 pt-md-0">
              <div class="form-check">
                <label class="form-check-label">
                  <%= checkbox(f, :email_notification,
                    class: "form-check-input",
                    disabled: @test.user == nil
                  ) %> &nbsp;&nbsp;<%= dgettext("test", "Notify me by email when a test is taken") %>
                </label>
                <div :if={@test.user == nil} class="form-text">
                  <%= dgettext("test", "Available only for logged in users") %>
                </div>
              </div>
            </div>
            <div class="col-12 col-md-6 pt-3 pt-md-0">
              <div class="form-check">
                <label class="form-check-label">
                  <%= checkbox(f, :allow_retake, class: "form-check-input") %> &nbsp;&nbsp;<%= dgettext(
                    "test",
                    "Allow a visitor to take the test multiple times."
                  ) %>
                </label>
              </div>
            </div>
          </div>
          <div class="row">
            <div class="col-12 col-md-6 mb-2 mb-sm-0">
              <div class="form-check">
                <label class="form-check-label">
                  <%= checkbox(f, :password_enabled, class: "form-check-input") %>
                  <%= hidden_input(f, :password) %> &nbsp;&nbsp;<%= dgettext(
                    "test",
                    "Password protected"
                  ) %>
                </label>
                <div class="form-text">
                  <%= dgettext(
                    "test",
                    "The test will require a password to be taken (public tests will be modified as private)"
                  ) %>
                </div>
              </div>
              <%= hidden_input(f, :password_length) %>
              <%= if @test.password_enabled == true and @test.password_length != nil do %>
                <div class="form-check mt-2 mb-3">
                  <%= dgettext("test", "Current:") %>&nbsp;
                  <%= for _star <- 1..@test.password_length do %>
                    *
                  <% end %>
                </div>
              <% end %>
              <div class="form-check mt-2 mb-1">
                <%= password_input(f, :password_input,
                  class: "form-control w-75",
                  placeholder: dgettext("test", "Enter new password")
                ) %>
                <%= error_tag(f, :password_input) %>
              </div>
            </div>
            <div class="col-12 col-md-6">
              <%= if get_field(@changeset, :type) != :listening do %>
                <div class="form-check">
                  <label class="form-check-label">
                    <%= checkbox(f, :to_close_at_enabled, class: "form-check-input") %> &nbsp;&nbsp;<%= dgettext(
                      "test",
                      "Close the test at date/time"
                    ) %>
                  </label>
                  <div class="form-text">
                    <%= dgettext(
                      "test",
                      "The test won't be able to be taken after this date/time, but results will still be available"
                    ) %>
                  </div>
                </div>
                <div class="form-check mt-2 mb-1">
                  <%= datetime_local_input(f, :to_close_at, class: "form-control w-75") %>
                  <%= error_tag(f, :to_close_at) %>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </fieldset>

      <fieldset>
        <legend class="header-typographica">
          <span
            class="float-end fs-8 text-body-secondary"
            style="font-family: var(--bs-font-sans-serif); padding-top: 12px;"
          >
            <i class="bi bi-info-circle"></i>&nbsp;<%= dgettext("test", "Two tracks minimum") %>
          </span>
          Tracks
        </legend>

        <%= if @test_updatable == false do %>
          <div class="alert alert-warning alert-thin">
            <i class="bi bi-x-circle"></i>&nbsp;&nbsp;<%= dgettext(
              "test",
              "Tracks can't be added or removed once at least one person has taken the test."
            ) %>
          </div>
        <% else %>
          <div class="alert alert-info alert-thin">
            <i class="bi bi-info-circle"></i>&nbsp;&nbsp;<%= dgettext(
              "test",
              "Supported formats: wav, mp3, aac, flac ... "
            ) %> <a
              href="https://en.wikipedia.org/wiki/HTML5_audio#Supported_audio_coding_formats"
              target="_blank"
            >(html5 audio)</a>. <%= dgettext("test", "Wav files are converted to flac (16bits 48k).") %>
          </div>
        <% end %>

        <fieldset class="form-group mb-3">
          <div class="form-unit p-3 rounded-3">
            <div class="form-check">
              <div class="d-flex justify-content-between">
                <label class="form-check-label">
                  <%= checkbox(f, :normalization, class: "form-check-input") %> &nbsp;&nbsp;<%= dgettext(
                    "test",
                    "Apply EBU R128 loudness normalization during upload (wav files only)"
                  ) %>
                </label>
                <div class="text-body-secondary text-end">
                  <small>
                    <i class="bi bi-info-circle"></i>&nbsp; <%= dgettext(
                      "test",
                      "True Peak -1dB, target -24dB"
                    ) %>
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
                <%= label(:f, :filename, "Select file(s) to upload:",
                  class: "col-sm-4 col-form-label text-start text-md-end"
                ) %>
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
                <%= label(:f, :upload_url, dgettext("test", "Add file from url:"),
                  class: "col-sm-4 col-form-label text-start text-md-end mt-2 mt-md-0"
                ) %>
                <div class="col">
                  <div class="input-group">
                    <%= url_input(f, :upload_url, class: "form-control", disabled: !@test_updatable) %>
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
                    <i class="bi bi-plus-lg"></i> <%= dgettext("test", "Add") %>
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
        <i class="bi bi-info-circle"></i>&nbsp;&nbsp; <%= raw(
          dgettext(
            "test",
            "Please use descriptive names to have relevant results. Tracks are <u>anonymized</u> and <u>randomized</u> on the test page (as seen on the <a target=\"_blank\" href=\"/test/demo\">demo</a>)."
          )
        ) %>
      </div>

      <div
        :if={
          get_field(@changeset, :type) == :listening and get_field(@changeset, :public) == true and
            track_count(@changeset) > 0
        }
        class="alert alert-warning alert-thin"
      >
        <i class="bi bi-info-circle"></i>&nbsp;&nbsp; <%= raw(
          dgettext("test", "Please use descriptive names.")
        ) %>
      </div>

      <%= error_tag(f, :tracks) %>

      <fieldset>
        <div class={["mb-2 py-1 rounded-3 form-unit", track_count(@changeset) === 0 && "d-none"]}>
          <.inputs_for :let={fp} field={f[:tracks]}>
            <%= if input_value(fp, :id) != nil do %>
              <%= hidden_input(fp, :id) %>
              <%= hidden_input(fp, :delete) %>
            <% else %>
              <%= hidden_input(fp, :temp_id) %>
            <% end %>

            <%= if input_value(fp, :url) != nil do %>
              <%= hidden_input(fp, :url) %>
            <% end %>

            <%= hidden_input(fp, :original_filename) %>
            <%= hidden_input(fp, :filename) %>

            <%= unless Enum.member?(@tracks_to_delete, input_value(fp, :id)) == true do %>
              <div class={"row p-2 mx-0#{unless input_value(fp, :id) == nil, do: " mb-2"}"}>
                <label class="col-sm-1 col-form-label">
                  <%= dgettext("test", "Track #%{track_index}", track_index: fp.index + 1) %>
                </label>
                <hr class="d-block d-sm-none mb-0" />
                <%= label(:fp, :title, dgettext("test", "Name:*"),
                  class: "col-sm-1 col-form-label text-start text-md-end"
                ) %>
                <div class="col-sm-4">
                  <%= text_input(fp, :title, class: "form-control", required: true) %>
                </div>
                <%= if get_upload_entry(input_value(fp, :temp_id), @uploads.tracks.entries) != nil and get_upload_entry_progress(input_value(fp, :temp_id), @uploads.tracks.entries) > 0 do %>
                  <%= label(:fp, :filename, dgettext("test", "Upload:"),
                    class: "col-sm-1 col-form-label text-start text-md-end mt-2 mt-md-0"
                  ) %>
                  <div class="col d-flex align-items-center">
                    <progress
                      value={
                        get_upload_entry_progress(input_value(fp, :temp_id), @uploads.tracks.entries)
                      }
                      max="100"
                    >
                      <%= get_upload_entry_progress(
                        input_value(fp, :temp_id),
                        @uploads.tracks.entries
                      ) %>%
                    </progress>
                  </div>
                <% else %>
                  <%= label(:fp, :filename, "File:",
                    class: "col-sm-1 col-form-label text-start text-md-end mt-2 mt-md-0"
                  ) %>
                  <div
                    class="col w-100 text-truncate d-flex align-items-center"
                    title={input_value(fp, :original_filename)}
                  >
                    <%= input_value(fp, :original_filename) %>
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

                  <label :if={Tests.can_have_reference_track?(@changeset)} class="col-form-label pe-3">
                    <%= checkbox(fp, :reference_track,
                      class: "form-check-input",
                      disabled: !@test_updatable
                    ) %> &nbsp;&nbsp;<%= dgettext(
                      "test",
                      "Reference"
                    ) %> &nbsp;<i
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

      <div class="mt-3 text-center text-md-end d-flex flex-row justify-content-end align-items-center">
        <div class="pe-2"><%= error_tag(f, :type) %></div>
        <div class="loading-spinner spinner-border spinner-border-sm text-primary me-2" role="status">
          <span class="visually-hidden"><%= dgettext("test", "Loading...") %></span>
        </div>
        <%= if @action == "save" do %>
          <button
            type="submit"
            class="btn btn-lg btn-primary"
            phx-disable-with="Saving..."
            disabled={!@changeset.valid? or @test_submittable == false}
          >
            <%= dgettext("test", "Save test") %>
          </button>
        <% else %>
          <button
            type="submit"
            class="btn btn-lg btn-primary"
            phx-disable-with={dgettext("site", "Updating ...")}
            disabled={!@changeset.valid? or @test_submittable == false}
          >
            <%= dgettext("test", "Update test") %>
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
             Map.get(session, "current_user_id") == test.user_id do
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
           nil -> nil
           token -> Accounts.get_user_by_session_token(token)
         end
       end)
       |> assign(%{
         page_title:
           dgettext("test", "Edit test - %{title}",
             title: String.slice(test.title, 0..@title_max_length)
           ),
         page_id: Utils.get_page_id_from_socket(socket),
         action: "update",
         changeset: changeset,
         test: Map.put(test, :to_close_at_timezone, get_timezone(socket)),
         view_description: false,
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
        {:ok, redirect(socket, to: ~p"/test")}
    end
  end

  # New
  @impl true
  def mount(params, session, socket) do
    user =
      case session["user_token"] do
        nil -> nil
        token -> Accounts.get_user_by_session_token(token)
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
     |> assign_new(:current_user, fn ->
       case session["user_token"] do
         nil -> nil
         token -> Accounts.get_user_by_session_token(token)
       end
     end)
     |> assign(%{
       page_title: dgettext("test", "Create test"),
       page_id: Utils.get_page_id_from_socket(socket),
       action: "save",
       changeset: changeset,
       test: test,
       view_description: false,
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
    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_assoc(:tracks, socket.assigns.test.tracks)

    dgettext("test", "Someone just took this test !")
    |> Utils.send_success_toast(socket.assigns.page_id)

    {:noreply,
     assign(socket, %{changeset: changeset, test_updatable: false, tracks_to_delete: []})}
  end

  def handle_info({:redirect, url, text} = _payload, socket) do
    {:noreply,
     socket
     |> put_flash(:success, text)
     |> push_navigate(to: url)}
  end

  def handle_info(:invitations_updated, socket) do
    Tests.clean_get_test_cache(socket.assigns.test)

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

        Tests.clean_get_test_cache(socket.assigns.test)
        FunkyABXWeb.Endpoint.broadcast!(socket.assigns.test.id, "test_updated", nil)

        if Ecto.Changeset.fetch_change(update_changeset, :to_close_at_enabled) !== :error or
             Ecto.Changeset.fetch_change(update_changeset, :to_close_at) !== :error do
          case test.to_close_at_enabled do
            true -> TestClosing.insert_test_to_closing_queue(test)
            false -> TestClosing.remove_test_from_closing_queue(test)
          end
        end

        # Delete files from removed tracks
        socket.assigns.test.tracks
        |> Enum.filter(fn t -> t.id in socket.assigns.tracks_to_delete end)
        |> Enum.map(fn t -> t.filename end)
        |> Files.delete(socket.assigns.test.id)

        dgettext("test", "Your test has been successfully updated.")
        |> Utils.send_success_toast(socket.assigns.page_id)

        test = Tests.get_edit(test.slug)
        changeset = Test.changeset_update(test)

        {:noreply, assign(socket, test: test, changeset: changeset, test_submittable: true)}

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
        if test.to_close_at_enabled == true, do: TestClosing.insert_test_to_closing_queue(test)

        # logged or not
        redirect =
          unless test.password == nil do
            ~p"/edit/#{test.slug}/#{test.password}"
          else
            ~p"/edit/#{test.slug}"
          end

        link = url(~p"/test/#{test.slug}")

        flash_text =
          gettext(
            "Your test has been successfully created !<br><br>You can now share the <a href=\"%{link}\">test's public link</a> for people to take it.",
            link: link
          )
          |> raw()

        dgettext("test", "Your test has been successfully created !")
        |> Utils.send_success_toast(socket.assigns.page_id)

        Process.send_after(
          self(),
          {:redirect, redirect <> "#top", flash_text},
          1500
        )

        changeset = Test.changeset_update(test)

        Logger.info("Test created (#{test.slug} / #{test.type} / #{length(test.tracks)} tracks)")

        # Refresh user test list if logged
        unless test.user == nil do
          Tests.clean_get_user_cache(test.user)
        end

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
          |> put_flash(:success, flash_text)
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.warning(
          "Test creating failed (#{fetch_field!(changeset, :type)} / #{length(fetch_field!(changeset, :tracks))} tracks)"
        )

        Utils.send_error_toast(socket.assigns.page_id)

        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  # ---------- MISC EVENTS ----------

  @impl true
  def handle_event("clipboard", %{"text" => text}, socket) do
    {:noreply, push_event(socket, "clipboard", %{text: text})}
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
       upload_url: test_params["upload_url"],
       description: test_params["description"],
       description_markdown: test_params["description_markdown"] == "true"
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

    Tests.clean_get_test_cache(test)

    # update data
    test = Tests.get_edit(test.slug)

    case Tests.is_closed?(test) do
      false -> FunkyABXWeb.Endpoint.broadcast!(test.id, "test_opened", nil)
      true -> FunkyABXWeb.Endpoint.broadcast!(test.id, "test_closed", nil)
    end

    changeset = Test.changeset_update(test)

    dgettext("test", "Your test has been successfully updated.")
    |> Utils.send_success_toast(socket.assigns.page_id)

    {:noreply, assign(socket, test: test, changeset: changeset, test_submittable: true)}
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

    TestClosing.remove_test_from_closing_queue(test)
    Tests.clean_get_test_cache(test)
    # Refresh user test list if logged
    unless test.user == nil or test.user.id == nil do
      Tests.clean_get_user_cache(test.user)
    end

    FunkyABXWeb.Endpoint.broadcast!(test.id, "test_deleted", nil)

    flash_text = dgettext("test", "Your test has been successfully deleted.")

    Utils.send_success_toast(flash_text, socket.assigns.page_id)

    Process.send_after(
      self(),
      {:redirect, ~p"/info", flash_text},
      1500
    )

    Logger.info("Test deleted (#{test.slug})")

    {
      :noreply,
      socket
      |> push_event("deleteTest", %{
        test_id: test.id,
        test_access_key: test.access_key
      })
      |> put_flash(:success, flash_text)
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

  @impl true
  def handle_event("toggle_description", _value, socket) do
    toggle = !socket.assigns.view_description

    {:noreply, assign(socket, view_description: toggle)}
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
            Utils.send_error_toast(
              "Error downloading #{t["original_filename"]}",
              socket.assigns.page_id
            )

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
