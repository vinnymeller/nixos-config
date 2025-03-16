let
  vindows-vinny = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILL1ICSjnFqxiAFubcpOSZN1vuNo/w4sTJoWXpfYnhoq";
  vinnix-vinny = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAOh+L9Lv8ai9K6q26k9rqUmnYorThf1g4FTUAS6NGws";
  vindows2-vinny = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIETu10Qstl8QNkrSAHSaH/AzNdRRa7jjnGFSZ5S84clW";
  users = [
    vindows-vinny
    vindows2-vinny
    vinnix-vinny
  ];

  vindows = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMFfKSa6jvWn/K+jXzntb1AGHbhfLGsjbS50U5kwjPsR";
  vinnix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBYDnYYFjCnSjyBb6ijuqNX6zLb/ItHQRm7MY9toHO8B";
  vindows2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL0jGSXLTCAm2wX7jLiLrMvhTfyfk79A8+c8r0vM9y8M";
  systems = [
    vindows
    vindows2
    vinnix
  ];
in
{
  "github-nix-ci/mxves.token.age".publicKeys = users ++ systems;
  "cloudflared/moves/credentials.json.age".publicKeys = users ++ systems;
  "shell/secrets.sh.age".publicKeys = users ++ systems;
}
