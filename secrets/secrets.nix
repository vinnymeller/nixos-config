let
  vindows-vinny = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILL1ICSjnFqxiAFubcpOSZN1vuNo/w4sTJoWXpfYnhoq";
  users = [ vindows-vinny ];

  vindows = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMFfKSa6jvWn/K+jXzntb1AGHbhfLGsjbS50U5kwjPsR";
  systems = [ vindows ];
in
{
  "github-nix-ci/mxves.token.age".publicKeys = users ++ systems;
}
