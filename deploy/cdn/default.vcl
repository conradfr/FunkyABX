vcl 4.0;

backend default {
  .host = "cdn-funkyabx.s3.fr-par.scw.cloud";
  .port = "80";
}

sub vcl_backend_fetch
{
  set bereq.http.Host = "cdn-funkyabx.s3.fr-par.scw.cloud";
}

sub vcl_deliver {
    if (req.http.origin ~ "funkybits.fr") {
      set resp.http.Access-Control-Allow-Origin = req.http.origin;
    }

        if (req.http.origin ~ "localhost") {
          set resp.http.Access-Control-Allow-Origin = "*";
        }

    set resp.http.Access-Control-Allow-Methods = "GET, OPTIONS";
    set resp.http.Access-Control-Allow-Headers = "Origin, Accept, Content-Type, X-Requested-With, X-CSRF-Token";
}

sub vcl_backend_response {
    # Happens after we have read the response headers from the backend.
    #
    # Here you clean the response headers, removing silly Set-Cookie headers
    # and other mistakes your backend does.

    if (beresp.status == 301 || beresp.status == 302) {
      set beresp.http.Location = regsub(beresp.http.Location, ":[0-9]+", "");
        set beresp.uncacheable = true;
        set beresp.ttl = 120s;
        return (deliver);
    }

     if (bereq.url ~ "^[^?]*\.(7z|avi|aac|bz2|flac|flv|gz|mka|mkv|mov|mp3|mp4|mpeg|mpg|ogg|ogm|opus|rar|tar|tgz|tbz|txz|wav|webm|xz|zip)(\?.*)?$") {
          unset beresp.http.set-cookie;
          set beresp.do_stream = true;  # Check memory usage it'll grow in fetch_chunksize blocks (128k by default) if the backend doesn't send a Content-Length header, so only enable it for big objects
        }
        return (deliver);
}

sub vcl_recv {
    # Remove all cookies for static files
    # A valid discussion could be held on this line: do you really need to cache static files that don't cause load? Only if you have memory left.
    # Sure, there's disk I/O, but chances are your OS will already have these files in their buffers (thus memory).
    # Before you blindly enable this, have a read here: https://ma.ttias.be/stop-caching-static-files/
    if (req.url ~ "^[^?]*\.(7z|avi|aac|bmp|bz2|css|csv|doc|docx|eot|flac|flv|gif|gz|ico|jpeg|jpg|js|less|mka|mkv|mov|mp3|mp4|mpeg|mpg|odt|otf|ogg|ogm|opus|pdf|png|ppt|pptx|rar|rtf|svg|svgz|swf|tar|tbz|tgz|ttf|txt|txz|wav|webm|webp|woff|woff2|xls|xlsx|xml|xz|zip)(\?.*)?$") {
      unset req.http.Cookie;
      return (hash);
    }
}
