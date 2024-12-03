# mix release

Here are some useful release commands you can run in any release environment:

    # To build a release
    mix release

    # To start your system with the Phoenix server running
    _build/dev/rel/vmemo/bin/server

    # To run migrations
    _build/dev/rel/vmemo/bin/migrate

Once the release is running you can connect to it remotely:

    _build/dev/rel/vmemo/bin/vmemo remote

To list all commands:

    _build/dev/rel/vmemo/bin/vmemo

https://hexdocs.pm/phoenix/releases.html#containers
