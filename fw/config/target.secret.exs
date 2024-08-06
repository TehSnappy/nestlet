import Config

config :nestlet, NestletWeb.Endpoint,
  secret_key_base: "XKsncMjyJtbYINNCO4omSkczoTUB4cABDgjGibcPS7/9AjzTth6bwkgL/ldVz2vr",
  live_view: [signing_salt: "y/9OESlX"]

config :nestlet, Nestlet.Nest.State,
  project_id: "0b0f0191-ec82-4606-a9cb-8daf2c44e60c",
  oauth_client_id: "348604309150-368us0b6nocph8gprct1rm6l87dr9k8r.apps.googleusercontent.com",
  oauth_client_secret: "oYp4I11ASwy5QmpDU35jsXfo"
