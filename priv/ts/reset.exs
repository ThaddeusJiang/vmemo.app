# mix run priv/ts/reset.exs
# Typesense setup is same as reset, and not need to seed data.

alias Vmemo.Ts

Ts.reset()
