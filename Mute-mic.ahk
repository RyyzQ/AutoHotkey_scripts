#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
SetBatchLines -1

Pause::

volume = 95
ComponentTypes = MASTER ; ComponentTypes to look through. Possible options: VOLUME,ONOFF,MUTE,MONO,LOUDNESS,STEREOENH,BASSBOOST,PAN,QSOUNDPAN,BASS,TREBLE,EQUALIZER,0x00000000, 0x10010000,0x10020000,0x10020001,0x10030000,0x20010000,0x21010000,0x30040000,0x30020000,0x30030000,0x30050000,0x40020000,0x50030000,0x70010000,0x70010001,0x71010000,0x71010001,0x60030000,0x61030000
ControlTypes = VOLUME ; ControlTypes to look through. Possible options: MASTER,HEADPHONES,DIGITAL,LINE,MICROPHONE,SYNTH,CD,TELEPHONE,PCSPEAKER,WAVE,AUX,ANALOG,N/A
micnumber := getDeviceNumber(volume, ComponentTypes, ControlTypes)

SoundSet, +1, MASTER, mute, 10
SoundGet, master_mute, , mute, 10

ToolTip, Mute %master_mute% ;use a tool tip at mouse pointer to show what state mic is after toggle
SetTimer, RemoveToolTip, 1000
return

RemoveToolTip:
SetTimer, RemoveToolTip, Off
ToolTip
return

getDeviceNumber(soundval, ComponentTypes, ControlTypes) {
    Loop  ; For each mixer number that exists in the system, query its capabilities.
    {
        CurrMixer := A_Index
        SoundGet, Setting,,, %CurrMixer%

        lowval := soundval - 0.25 ; lowval & highval are used because for some reason setting volume doesn't always end up being a whole number. Or at least AHK doesn't think it does.
        highval := soundval + 0.25 ; Using 0.25 should at least guarantee it not grabbing any other close audio devices (set at soundval + 1 for example)

        if (Setting >= lowval AND Setting <= highval) 
        {
            if ErrorLevel = Can't Open Specified Mixer  ; Any error other than this indicates that the mixer exists.
                break

            ; For each component type that exists in this mixer, query its instances and control types:
            Loop, parse, ComponentTypes, `,
            {
                CurrComponent := A_LoopField
                ; First check if this component type even exists in the mixer:
                SoundGet, Setting, %CurrComponent%,, %CurrMixer%
                if ErrorLevel = Mixer Doesn't Support This Component Type
                    continue  ; Start a new iteration to move on to the next component type.
                Loop  ; For each instance of this component type, query its control types.
                {
                    CurrInstance := A_Index
                    ; First check if this instance of this instance even exists in the mixer:
                    SoundGet, Setting, %CurrComponent%:%CurrInstance%,, %CurrMixer%
                    ; Checking for both of the following errors allows this script to run on older versions:
                    if ErrorLevel in Mixer Doesn't Have That Many of That Component Type,Invalid Control Type or Component Type
                        break  ; No more instances of this component type.
                    ; Get the current setting of each control type that exists in this instance of this component:
                    Loop, parse, ControlTypes, `,
                    {
                        CurrControl := A_LoopField
                        SoundGet, Setting, %CurrComponent%:%CurrInstance%, %CurrControl%, %CurrMixer%
                        ; Checking for both of the following errors allows this script to run on older versions:
                        if ErrorLevel in Component Doesn't Support This Control Type,Invalid Control Type or Component Type
                            continue
                        if ErrorLevel  ; Some other error, which is unexpected so show it in the results.
                            Setting := ErrorLevel
                        ComponentString := CurrComponent
                        if CurrInstance > 1
                            ComponentString = %ComponentString%:%CurrInstance%
                        if (Setting >= lowval AND settingval <= highval) {
                            return %CurrMixer%
                        }
                    }  ; For each control type.
                }  ; For each component instance.
            }  ; For each component type.
        }  
    }  ; For each mixer.
}