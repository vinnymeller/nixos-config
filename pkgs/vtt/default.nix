{ pkgs, ... }:

let
  model = pkgs.fetchurl {
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3.bin";
    hash = "sha256-ZNGCtEC5jVIDxPm9VBVE2ExgUZbE97hF36EfsjWU0eI=";
  };
in

pkgs.writeShellApplication {
  name = "vtt";
  runtimeInputs = with pkgs; [
    coreutils
    libnotify
    sox
    whisper-cpp
    wtype
  ];

  text = builtins.replaceStrings [ "@MODEL_PATH@" ] [ "${model}" ] (builtins.readFile ./vtt.sh);
}
