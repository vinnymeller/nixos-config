let
  vindows-vinny = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILL1ICSjnFqxiAFubcpOSZN1vuNo/w4sTJoWXpfYnhoq";
  vindows2-vinny = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIETu10Qstl8QNkrSAHSaH/AzNdRRa7jjnGFSZ5S84clW";
  vinnix-vinny = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFoRbq0n9c2nQrybutvezLaFovI/m0AVYe+jVyY8cntI";
  users = [
    vindows-vinny
    vindows2-vinny
    vinnix-vinny
  ];

  vindows = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMFfKSa6jvWn/K+jXzntb1AGHbhfLGsjbS50U5kwjPsR";
  vindows2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL0jGSXLTCAm2wX7jLiLrMvhTfyfk79A8+c8r0vM9y8M";
  vinnix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOb7XeaMlqn5hmmpvWG133WED1tsD6RdBECJ8doqQUAL";
  systems = [
    vindows
    vindows2
    vinnix
  ];

  camovinny = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILieUmZBNFDpv/dCbfqC0hgfH2hdrCYYz2Jag4+jQe2A";
  camovinny-vinny = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJD0xnm6ozJiSEPX6ot9qADGPPXWuePO+kjwTM3RYgWL";
  work = [
    camovinny
    camovinny-vinny
  ];

in
{
  "github-nix-ci/mxves.token.age".publicKeys = users ++ systems;
  "cloudflared/moves/credentials.json.age".publicKeys = users ++ systems;
  "shell/secrets.sh.age".publicKeys = users ++ systems ++ work;
}
