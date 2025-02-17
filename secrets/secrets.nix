let
  vindows-vinny = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILL1ICSjnFqxiAFubcpOSZN1vuNo/w4sTJoWXpfYnhoq";
  vinnix-vinny = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAOh+L9Lv8ai9K6q26k9rqUmnYorThf1g4FTUAS6NGws";
  users = [
    vindows-vinny
    vinnix-vinny
  ];

  vindows = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMFfKSa6jvWn/K+jXzntb1AGHbhfLGsjbS50U5kwjPsR";
  vinnix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBYDnYYFjCnSjyBb6ijuqNX6zLb/ItHQRm7MY9toHO8B";
  systems = [
    vindows
    vinnix
  ];
in
{
  "github-nix-ci/mxves.token.age".publicKeys = users ++ systems;
}
