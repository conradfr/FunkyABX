defmodule DisqusComponent do
  use Phoenix.Component
  use FunkyABXWeb, :html
  use Phoenix.VerifiedRoutes, endpoint: FunkyABXWeb.Endpoint, router: FunkyABXWeb.Router

  alias FunkyABX.Test

  attr :test, Test, required: true

  def load(assigns) do
    ~H"""
    <div phx-update="ignore" id="disqus">
      <div class="test-comments mt-5">
        <h5 class="header-neon"><%= dgettext("test", "Comments") %></h5>
        <div id="disqus_thread"></div>
        <script id="disqus_thread_js">
          var disqus_config = function () {
          this.page.url = '<%= url(~p"/results/#{@test.slug}") %>';
          this.page.identifier = '<%= NaiveDateTime.to_iso8601(@test.inserted_at) %>-<%= @test.slug %>';
          };
            (function() {
              var d = document, s = d.createElement('script');
              s.src = 'https://<%= Application.fetch_env!(:funkyabx, :disqus_id) %>.disqus.com/embed.js';
              s.setAttribute('data-timestamp', +new Date());
              (d.head || d.body).appendChild(s);
            })();
        </script>
        <script
          id="dsq-count-scr"
          src={"//#{Application.fetch_env!(:funkyabx, :disqus_id)}.disqus.com/count.js"}
          async
        >
        </script>
      </div>
    </div>
    """
  end
end
