#!/usr/bin/env bash

# thanks to reddit user turqpanda
# https://pastebin.com/ePpgfYe5

# Figure out the right source and sinks to use
MIC_SOURCE=$(pactl info | grep 'Default Source' | awk '{ print $NF; }')
RAW_MIC_SOURCE=$MIC_SOURCE
OUTPUT_SINK=$(pactl info | grep 'Default Sink' | awk '{ print $NF; }')
SAMPLE_RATE=$(pactl info | grep 'Default Sample' | awk '{ print $NF; }' | head -c -3)


# Now setup the rnnoise-magic too if requested
if [ "$1" == "with-rnnoise" ]; then
    LADSPA_RNNOISE_PLUGIN=/path/to/noise-suppression-for-voice/build/bin/ladspa/librnnoise_ladspa.so

    DENOISE_LEVEL=50

    # Create the virtual sink for rnnoise plugin to output to
    # The monitor of this sink will be the denoised mic
    pacmd load-module module-null-sink sink_name=DenoisedMic sink_properties=device.description=DenoisedMic format=s16le channels=2 rate="$SAMPLE_RATE"

    # Create the LADSPA RNNoise filter sink that will do the actual noise removal
    pacmd load-module module-ladspa-sink sink_name=RawMicIn sink_master=DenoisedMic label=noise_suppressor_mono plugin="$LADSPA_RNNOISE_PLUGIN" control="$DENOISE_LEVEL"

    # Now feed the mic into the LADSPA sink
    pacmd load-module module-loopback source="$MIC_SOURCE" sink=RawMicIn channels=1 source_dont_move=true sink_dont_move=true latency_msec=1

    # Override the MIC_SOURCE to use the denoised version
    MIC_SOURCE=DenoisedMic.monitor
fi

echo -e "Raw Source: \t$RAW_MIC_SOURCE\nSource: \t$MIC_SOURCE\nSink: \t\t$OUTPUT_SINK\nSample Rate: \t$SAMPLE_RATE"

# Create virtual Sink used for any playback we want to capture
# i.e. set Firefox to use this if you want browser audio in your "mic"
pacmd load-module module-null-sink sink_name=CapturedAudio sink_properties=device.description=CapturedAudio format=s16le channels=2 rate="$SAMPLE_RATE"

# Create virtual sink to be used as the final "mic"
# i.e. the monitor of this sink will be used as the default input
pacmd load-module module-null-sink sink_name=CombinedAudio sink_properties=device.description=CombinedAudio format=s16le channels=2 rate="$SAMPLE_RATE"

# Use loopback to feed the mic audio & CapturedAudio's monitor into the CombinedAudio sink
pacmd load-module module-loopback source="$MIC_SOURCE" sink=CombinedAudio latency_msec=1
pacmd load-module module-loopback source=CapturedAudio.monitor sink=CombinedAudio latency_msec=1

# Use another loopback to also feed the CapturedAudio back to the local output so we can hear it too
pacmd load-module module-loopback source=CapturedAudio.monitor sink="$OUTPUT_SINK" latency_msec=1

# Now make the CombinedAudio monitor the default input
pactl set-default-source CombinedAudio.monitor

# Now for any application you want to be included in CombinedAudio.monitor source, set it to use the CapturedAudio sink
# with pavucontrol or otherwise


