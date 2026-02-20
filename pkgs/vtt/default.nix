{
  pkgs,
  geminiKeyFile,
}:

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
    curl
    hyprland
    hyprshot
    jq
    libnotify
    procps
    sox
    tmux
    whisper-cpp
    ydotool
  ];

  text =
    builtins.replaceStrings
      [
        "@MODEL_PATH@"
        "@GEMINI_KEY_FILE@"
      ]
      [
        "${model}"
        geminiKeyFile
      ]
      (builtins.readFile ./vtt.sh);
}
