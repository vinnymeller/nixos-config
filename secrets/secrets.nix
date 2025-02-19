let
  vindows-vinny = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILL1ICSjnFqxiAFubcpOSZN1vuNo/w4sTJoWXpfYnhoq";
  vinnix-vinny = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAOh+L9Lv8ai9K6q26k9rqUmnYorThf1g4FTUAS6NGws";
  camo-vinny = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJD0xnm6ozJiSEPX6ot9qADGPPXWuePO+kjwTM3RYgWL";
  users = [
    vindows-vinny
    vinnix-vinny
    camo-vinny
  ];

  vindows = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMFfKSa6jvWn/K+jXzntb1AGHbhfLGsjbS50U5kwjPsR";
  vinnix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBYDnYYFjCnSjyBb6ijuqNX6zLb/ItHQRm7MY9toHO8B";
  systems = [
    vindows
    vinnix
  ];
in
{
  "github-nix-ci/mxves.token.age".publicKeys = [
    vindows-vinny
    vinnix-vinny
  ] ++ systems;
  "cloudflared/moves/credentials.json.age".publicKeys = systems;
  "zsh/secrets.sh.age".publicKeys = users ++ systems;
}
