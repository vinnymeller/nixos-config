let
  vindows-vinny = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHnPtGpoD/UfbeUKgsFSnMzbKsibgkUHe0ppmFDlDvoH";
  vinnix-vinny = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFoRbq0n9c2nQrybutvezLaFovI/m0AVYe+jVyY8cntI";
  users = [
    vindows-vinny
    vinnix-vinny
  ];

  vindows = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKuqngENRgYtvO04TxAt0eR+Qwbq+Ef/ATp0rd8PGkcp";
  vinnix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOb7XeaMlqn5hmmpvWG133WED1tsD6RdBECJ8doqQUAL";
  systems = [
    vindows
    vinnix
  ];

  camovinny = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILieUmZBNFDpv/dCbfqC0hgfH2hdrCYYz2Jag4+jQe2A";
  camovinny-vinny = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJD0xnm6ozJiSEPX6ot9qADGPPXWuePO+kjwTM3RYgWL";
  work = [
    camovinny
    camovinny-vinny
  ];

  host-vinnix = [
    vinnix
    vinnix-vinny
  ];
  host-vindows = [
    vindows
    vindows-vinny
  ];
  pc = host-vinnix ++ host-vindows;

  default = users ++ systems ++ work;

in
{
  "github-nix-ci/mxves.token.age".publicKeys = users ++ systems;
  "shell/secrets.sh.age".publicKeys = default;

  "vinnix/wpa_supplicant.conf.age".publicKeys = host-vinnix;
  "vinnix/immich.age".publicKeys = host-vinnix;
  "vinnix/grimmory.age".publicKeys = host-vinnix;
  "vinnix/cloudflare-dns-token.age".publicKeys = host-vinnix;
  "vinnix/paperless.age".publicKeys = host-vinnix;
  "vtt/gemini.age".publicKeys = host-vinnix;

  "vinnix/tailscale-authkey.age".publicKeys = pc;
  "vinnix/rclone.conf.age".publicKeys = pc;
  "vinnix/restic-password.age".publicKeys = pc;
  "vinnix/mullvad-wg-key.age".publicKeys = pc;
  "vinnix/airvpn-wg-key.age".publicKeys = pc;
  "vinnix/airvpn-wg-psk.age".publicKeys = pc;
}
