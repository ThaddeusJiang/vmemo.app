# mix run priv/ts/reset.exs
# Typesense setup is same as reset, and not need to seed data.

alias SmallSdk.Typesense
# drop all collections
Typesense.drop_collection("photos")
Typesense.drop_collection("notes")

# run all migrations
Vmemo.Ts.Migration20241203.define()
Vmemo.Ts.Migration20241219.define()
