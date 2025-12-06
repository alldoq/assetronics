import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# Load .env file in development - MUST happen before any config that uses env vars
if config_env() in [:dev, :test] do
  # Load .env file if it exists
  env_file = Path.join([__DIR__, "..", ".env"])
  if File.exists?(env_file) do
    # Read and parse .env file manually
    env_file
    |> File.read!()
    |> String.split("\n")
    |> Enum.each(fn line ->
      case String.trim(line) do
        # Skip empty lines and comments
        "" -> :ok
        "#" <> _ -> :ok
        line ->
          # Parse KEY=VALUE
          case String.split(line, "=", parts: 2) do
            [key, value] ->
              # Remove quotes if present
              clean_value = String.trim(value) |> String.trim("\"") |> String.trim("'")
              System.put_env(String.trim(key), clean_value)
            _ -> :ok
          end
      end
    end)
  end
end

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/assetronics start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :assetronics, AssetronicsWeb.Endpoint, server: true
end

# ## OAuth Configuration (for all environments)
# OAuth credentials are stored per-tenant in the database (integrations.auth_config).
# These are global configuration settings only.
config :assetronics,
  # OAuth redirect URI (backend callback endpoint)
  oauth_redirect_uri: System.get_env("OAUTH_REDIRECT_URI") || "http://localhost:4000/api/v1/oauth/callback",

  # Frontend URL (for post-OAuth redirects)
  frontend_url: System.get_env("FRONTEND_URL") || "http://localhost:5173"

  # Optional: Platform-level OAuth apps (if offering shared OAuth apps)
  # Most multi-tenant SaaS apps require each tenant to bring their own OAuth credentials.
  # microsoft_client_id: System.get_env("MICROSOFT_CLIENT_ID"),
  # microsoft_client_secret: System.get_env("MICROSOFT_CLIENT_SECRET"),
  # dell_client_id: System.get_env("DELL_CLIENT_ID"),
  # dell_client_secret: System.get_env("DELL_CLIENT_SECRET")

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :assetronics, Assetronics.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    # For machines with several cores, consider starting multiple pools of `pool_size`
    # pool_count: 4,
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :assetronics, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :assetronics, AssetronicsWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :assetronics, AssetronicsWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :assetronics, AssetronicsWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :assetronics, Assetronics.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney, Req and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.

  # ## Email Configuration (Resend)
  config :assetronics, Assetronics.Mailer,
    adapter: Swoosh.Adapters.Resend,
    api_key: System.get_env("RESEND_API_KEY")

  config :swoosh, :api_client, Swoosh.ApiClient.Finch

  config :assetronics,
    from_email: System.get_env("FROM_EMAIL") || "noreply@assetronics.com",
    from_name: System.get_env("FROM_NAME") || "Assetronics",
    support_email: System.get_env("SUPPORT_EMAIL") || "support@assetronics.com",
    app_url: System.get_env("APP_URL") || "https://app.assetronics.com"

  # ## File Storage Configuration
  #
  # Configure S3 for production file uploads
  config :assetronics,
    storage_provider: :s3,
    s3_bucket: System.get_env("AWS_S3_BUCKET"),
    s3_region: System.get_env("AWS_REGION") || "us-east-1"

  config :ex_aws,
    access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
    secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
    region: System.get_env("AWS_REGION") || "us-east-1"
end
