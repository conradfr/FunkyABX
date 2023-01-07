defmodule DisqusComponent do
  use FunkyABXWeb, :live_component

  alias FunkyABX.Test

  attr :test, Test, required: true

  def render(assigns) do
    ~H"""
      <div>
        <div :if={@test.local == false and !is_nil(Application.fetch_env!(:funkyabx, :disqus_id))} class="test-comments mt-5">
          <h5 class="header-neon"><%= gettext "Comments" %></h5>
          <div phx-update="ignore" id="disqus_thread"></div>
          <script phx-update="ignore" id="disqus_thread_js">
            var disqus_config = function () {
            this.page.url = '<%= Routes.test_results_public_url(@socket, FunkyABXWeb.TestResultsLive, @test.slug) %>';
            this.page.identifier = '<%= NaiveDateTime.to_iso8601(@test.inserted_at) %>-<%= @test.slug %>';
            };
              (function() {
                var d = document, s = d.createElement('script');
                s.src = 'https://<%= Application.fetch_env!(:funkyabx, :disqus_id) %>.disqus.com/embed.js';
                s.setAttribute('data-timestamp', +new Date());
                (d.head || d.body).appendChild(s);
              })();
          </script>
          <script id="dsq-count-scr" src={"//#{Application.fetch_env!(:funkyabx, :disqus_id)}.disqus.com/count.js"} async></script>
        </div>
      </div>
    """
  end
end
