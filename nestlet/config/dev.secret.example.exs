import Config

config :nestlet, NestletWeb.Endpoint,
  secret_key_base: "xxx",
  live_view: [signing_salt: "xxx"]

config :nestlet, Nestlet.Nest.State,
  project_id: "xxx",
  oauth_client_id: "xcc",
  oauth_client_secret: "xxx"
