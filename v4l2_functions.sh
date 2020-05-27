#!/usr/bin/env bash

#This function creates virtual video devices.
#Note, at this time, the devices are not associated with anything.
#To use the devies, you shall send streams to them.
#For example, `send_webcam_to_video_device()` below sends a webcam's raw input to devices.
function create_video_device() {
    if [[ $# == 0 || $1 == "-h" || $1 == "--help" ]]; then
        echo "Usage: create_video_device <device number(s)>"
        return 0
    fi
    if [[ -n $(lsmod | grep "^v4l2loopback ") ]]; then
        echo '`v4l2loopback` is already loaded.'
        return 0
    fi
    local command="sudo modprobe v4l2loopback exclusive_caps=1 video_nr=$1" #`exclusive_caps=1` is needed to make the created devices usable from Chrome. See |https://github.com/umlaeute/v4l2loopback| for the detail. (But it seemed an operation became much slower by the option.)
#     local command="sudo modprobe v4l2loopback video_nr=$1"
    local card_label_prefix="virtual_"
    local card_label_option="card_label=${card_label_prefix}$1"
    shift
    for device_number; do
        command="${command},${device_number}"
        card_label_option="${card_label_option},${card_label_prefix}${device_number}"
    done
    command="${command} ${card_label_option}"
    echo "Assembled Command: [ ${command} ]"
    ${command}
}

# function delete_all_video_devices() {
#     if [[ $1 == "-h" || $1 == "--help" ]]; then
#         echo "Usage: delete_all_video_devices"
#         return 0
#     fi
#     sudo modprobe --remove --verbose v4l2loopback #=> "modprobe: FATAL: Module v4l2loopback is in use." (by `videodev` according to `lsmod | grep v4l2loopback`)
# }

#This function sends raw input from a physical (i.e. real) webcam as it is to virtual video devices created by `v4l2loopback`.
#ref: |https://trac.ffmpeg.org/wiki/Capture/Webcam|
#ref: |https://github.com/umlaeute/v4l2loopback/wiki/Ffmpeg|
#ref: |https://trac.ffmpeg.org/wiki/Creating%20multiple%20outputs|
#Although this function can assemble a command which has two or more outputs, since such a `ffmpeg` command doesn't work(*) in this case for no reason, it rejects more than one arguments.
#(*): Actually it works with no error but the second output would be corrupted. In other words, the second output is available but not practically useful.
function send_webcam_to_video_device() {
    # if [[ $# == 0 || $1 == "-h" || $1 == "--help" ]]; then
    #     echo "Usage: send_webcam_to_video_device <output device number(s)>"
    #     return 0
    # fi
    if [[ $# != 1 || $1 == "-h" || $1 == "--help" ]]; then
        echo "Usage: send_webcam_to_video_device <output device number>"
        return 0
    fi
    local device_prefix="/dev/video"
    local input_device_number=0
    local command="ffmpeg -hide_banner -i ${device_prefix}${input_device_number}"
    for output_device_number; do
        command="${command} -map 0 -f v4l2 -codec:v rawvideo -codec:a copy -pix_fmt yuv420p ${device_prefix}${output_device_number}"
    done
    echo "Assembled Command: [ ${command} ]"
    ${command}
}

