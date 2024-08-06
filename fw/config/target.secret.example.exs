import Config

config :nestlet, NestletWeb.Endpoint,
  secret_key_base: "xxxxxxxxx",
  live_view: [signing_salt: "xxxxx"]

config :nestlet, Nestlet.Nest.State,
  project_id: "xxxxxxxxx",
  oauth_client_id: "xxxxxxxxx",
  oauth_client_secret: "xxxxxxxxx"
