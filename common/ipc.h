#pragma once

#define IPC_CMD_READ_FRAME            1
#define IPC_CMD_OPEN_FILE             2
#define IPC_CMD_CONTROL_AUDIO         3
#define IPC_CMD_READ_HEADER           4
#define IPC_CMD_GOTO_KEYFRAME         5
#define IPC_CMD_GOTO_NEAREST_KEYFRAME 6
#define IPC_CMD_SETUP_DLDI            13
#define IPC_CMD_HANDSHAKE             15

#define IPC_CMD_ARG_MASK       0x0FFFFFFF
#define IPC_CMD_CMD_SHIFT      28
#define IPC_CMD_CMD_MASK       0xF0000000
#define IPC_CMD_PACK(cmd, arg) ((((u32)(cmd) << IPC_CMD_CMD_SHIFT) & IPC_CMD_CMD_MASK) | ((u32)(arg)&IPC_CMD_ARG_MASK))

#define IPC_ARG_CONTROL_AUDIO_STOP       0
#define IPC_ARG_CONTROL_AUDIO_START      1
#define IPC_ARG_CONTROL_AUDIO_STOP_CLEAR 2
