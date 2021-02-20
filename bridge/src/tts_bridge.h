//
//  tts_bridge.h
//  
//
//  Created by Bruno Plantier on 12/12/2020.
//


#ifndef TTS_BRIDGE_H
#define TTS_BRIDGE_H

#include <stdbool.h>

// a dedicated struct used to store some informations about an available voice
typedef struct {
    const char* identifier;
    const char* name;
    const char* language;
} tts_VoiceData;

// initiliaze the speech engine
bool tts_init();
// finalize the speech engine
void tts_shutdown();
// say something
void tts_speak(const char* text);
// stop speaking
void tts_stop();
// pause speaking
void tts_pause();
// resume speaking
void tts_resume();
// is speaking
bool tts_isSpeaking();
// serialize speaking
void tts_speakToFile(const char* text, const char* filename);
// set the speech rate (1.0f for 200 words per minute)
bool tts_setRate(float rate);
// get the speech rate
float tts_getRate();
// set the pitch voice
bool tts_setPitch(float pitch);
// get the pitch voice
float tts_getPitch();
// set the volume using a floating point value in the range of 0.0 to 1.0 inclusive
bool tts_setVolume(float volume); 
// get the volume
float tts_getVolume();
// set the callback to call when these events occur :
//
void tts_setCallback(void* func);
// set the current voice using a string identifier (see tts_getAvailableVoices)
bool tts_setVoice(const char* voiceId); 
// get the current voice
tts_VoiceData tts_getVoice();
// get the list of available voices through a dedicated struct and a pseudo iterator mechanism
tts_VoiceData* tts_getFirstAvailableVoice(); 
tts_VoiceData* tts_getNextAvailableVoice(); 
#endif