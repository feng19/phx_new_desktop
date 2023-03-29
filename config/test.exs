import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :phx_new_desktop, PhxNewDesktopWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "ri1I4+SCFIaitF4p2nlFs59kBw+rVzBSSgC4ENoEAyl+bKWbLHO7GB832hHIzJPp",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
