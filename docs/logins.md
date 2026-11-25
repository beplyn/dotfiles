# Logins

Two kinds of login cover the apps:

- **Tinyauth apps:** you log in once with your passkey, and it covers all of them.
- **Pocket ID apps:** the app offers "log in with Pocket ID" next to its own login. See [pocket-id.md](pocket-id.md).
- **Own login:** apps that phone apps, extensions or other clients talk to. They have their own password.

Passwords are generated on the server, never stored in git. Read one with the command in the
[beacon cheat sheet](beacon.md#cheat-sheet).

## First-time setup

1. Go to `https://id.<domain>/setup` and create the admin: username `<username>`, your git email,
   and a passkey.
2. Optional: let apps log in with Pocket ID, see [pocket-id.md](pocket-id.md).
