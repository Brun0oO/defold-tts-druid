//
//  tts_darwin.mm
//  
//
//  Created by Bruno Plantier on 12/12/2020.
//

#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)
	#include "tts_private.h"
	#include <Foundation/Foundation.h>
	#include <dmsdk/dlib/log.h>

	//#define MYDEBUG

	#if defined(DM_PLATFORM_IOS) && defined(MYDEBUG)
		static tts_VoiceData emptyVoiceData = {"","",""};

		// initiliaze the speech engine
		bool tts_init() { assert(1=2, "STOP HERE!"); return true; }
		// finalize the speech engine
		void tts_shutdown() {}
		// say something
		void tts_speak(const char* text) {}
		// stop speaking
		void tts_stop() {}
		// pause speaking
		void tts_pause() {}
		// resume speaking
		void tts_resume() {}
		// is speaking
		bool tts_isSpeaking() { return true; }
		// serialize speaking
		void tts_speakToFile(const char* text, const char* filename) {}
		// set the speech rate (1.0f for 200 words per minute)
		bool tts_setRate(float rate) {return true; }
		// get the speech rate
		float tts_getRate() { return 0.0; }
		// set the pitch voice
		bool tts_setPitch(float pitch) { return true; }
		// get the pitch voice
		float tts_getPitch() { return 0.0; }
		// set the volume using a floating point value in the range of 0.0 to 1.0 inclusive
		bool tts_setVolume(float volume) { return true; }
		// get the volume
		float tts_getVolume() { return 0.0;}
		// set the callback to call when these events occur :
		//
		void tts_setCallback(void* func) {}
		// set the current voice using a string identifier (see tts_getAvailableVoices)
		bool tts_setVoice(const char* voiceId) { return true; }
		// get the current voice
		tts_VoiceData tts_getVoice() { return emptyVoiceData; }
		// get the list of available voices through a dedicated struct and a pseudo iterator mechanism
		tts_VoiceData* tts_getFirstAvailableVoice() { return NULL; }
		tts_VoiceData* tts_getNextAvailableVoice() { return NULL; }
	#else
		#if defined(DM_PLATFORM_IOS)
			#include <AVFoundation/AVFoundation.h>
			#define NSSpeechSynthesizer         AVSpeechSynthesizer
		#else // MAC OS
			#include <Cocoa/Cocoa.h>
		#endif


		#if defined(DM_PLATFORM_IOS)
			static AVSpeechSynthesisVoice*	tts_voice = NULL;
		#endif
		static float 					tts_rate = 1.0f;
		static float 					tts_volume = 1.0f;
		static float 					tts_pitch = 1.0f;
		#if defined(DM_PLATFORM_OSX)
			static int						tts_basePitch = 150;
		#endif
		static void* 					tts_callback = NULL;
		static bool						tts_initialized = false;
		static bool						tts_paused = false;

		static tts_VoiceData*			tts_availableVoiceData_buffer = NULL;
		static int						tts_availableVoiceData_count = 0;
		static int						tts_availableVoiceData_iter = 0;
		static int						tts_selectedVoiceData_index = -1;

		typedef struct Engine {
			NSSpeechSynthesizer* speechSynthesizer;
			NSString* currentLocale;
			NSString* lastString;
		} Engine;
		static Engine* pEngine = NULL;

		static tts_VoiceData emptyVoiceData = {"","",""};


		// some references used in this code :
		// https://chromium.googlesource.com/chromium/src/+/master/content/browser/speech/tts_mac.mm
		// https://gist.github.com/Koze/d9d6655d3a6d09259ba2#file-textspeechexample8-m
		// https://github.com/progrmr/SDK_Utilities/blob/master/GM_Subclasses/GMSpeech.m
		// https://github.com/jfield44/JFTextToSpeech/blob/master/JFTextToSpeech/JFViewController.m
		// https://openclassrooms.com/forum/sujet/affecter-un-const-char-avec-un-char-34222
		// https://github.com/WebKit/webkit/blob/main/Source/WebCore/platform/mac/PlatformSpeechSynthesizerMac.mm
		// https://github.com/WebKit/WebKit/blob/main/Source/WebCore/platform/ios/PlatformSpeechSynthesizerIOS.mm



		// get the list of available voices using a list of string identifiers
		// the function returns the count of available voices. 
		void tts_allocAvailableVoices() {
		#if defined(DM_PLATFORM_IOS)
			int count = 0;
			NSArray* voices = [AVSpeechSynthesisVoice speechVoices]; 
			NSMutableArray* orderedVoices = [NSMutableArray arrayWithCapacity:[voices count]];

			AVSpeechSynthesisVoice *voice = [AVSpeechSynthesisVoice voiceWithLanguage:[AVSpeechSynthesisVoice currentLanguageCode]];
			NSString* defaultVoice;
			if (voice) {
				defaultVoice = voice.name;
				[orderedVoices addObject:defaultVoice];
				count += 1;	
			}
			for (AVSpeechSynthesisVoice* voice in voices) {
				if (voice && ![voice.name isEqualToString:defaultVoice]) {
					[orderedVoices addObject:voice];
					count += 1;
				}
			}
			tts_availableVoiceData_buffer = (tts_VoiceData*) malloc(count * sizeof(*tts_availableVoiceData_buffer));
			tts_availableVoiceData_count = count;
			int index = 0;
			for (AVSpeechSynthesisVoice* voice in orderedVoices) {
				NSString* name = voice.name;
				NSString* lang = voice.language;
				NSString* voiceIdentifier = voice.identifier;

				const char* cIdendifier = [voiceIdentifier UTF8String];
				const char* cName = [name UTF8String];
				const char* cLanguage = [lang UTF8String];
				

				char* p = (char*) malloc(strlen(cName) + 1);
				strcpy(p, cName);
				tts_availableVoiceData_buffer[index].name = (const char*) p;

				p = (char*) malloc(strlen(cLanguage) + 1);
				strcpy(p, cLanguage);
				tts_availableVoiceData_buffer[index].language = (const char*) p;

				p = (char*) malloc(strlen(cIdendifier) + 1);
				strcpy(p, cIdendifier);
				tts_availableVoiceData_buffer[index].identifier = (const char*) p;

				index += 1;
			}
		#else // MAC OS
			int count = 0;
			NSArray* voices = [NSSpeechSynthesizer availableVoices];
			// Create a new temporary array of the available voices with
			// the default voice first.
			NSMutableArray* orderedVoices = [NSMutableArray arrayWithCapacity:[voices count]];

			NSString* defaultVoice = [NSSpeechSynthesizer defaultVoice];

			if (defaultVoice) {
				[orderedVoices addObject:defaultVoice];
				count += 1;
			}	
			for (NSString* voiceIdentifier in voices) {
				if (![voiceIdentifier isEqualToString:defaultVoice]) {
					[orderedVoices addObject:voiceIdentifier];
					count += 1;
				}
			}

			// Populate an internal buffer with references to the available voices
			tts_availableVoiceData_buffer =(tts_VoiceData*) malloc(count * sizeof(*tts_availableVoiceData_buffer));
			tts_availableVoiceData_count = count;
			int index = 0;
			// For each available voice
			for (NSString* voiceIdentifier in orderedVoices) {
				// Retrieve identifier, name and language from the NSObject
				NSDictionary* attributes = [NSSpeechSynthesizer attributesForVoice:voiceIdentifier];
				NSString* name = [attributes objectForKey:NSVoiceName];
				NSString* localeIdentifier = [attributes objectForKey:NSVoiceLocaleIdentifier];
				NSDictionary* localeComponents = [NSLocale componentsFromLocaleIdentifier:localeIdentifier];
				NSString* language = [localeComponents objectForKey:NSLocaleLanguageCode];
				NSString* country = [localeComponents objectForKey:NSLocaleCountryCode];
				NSString* lang;
				if (language && country) {
					lang = [NSString stringWithFormat:@"%@-%@", language, country];
				} else {
					lang = language;
				}

				// Get const char* pointers from NSString
				const char* cIdendifier = [voiceIdentifier UTF8String];
				const char* cName = [name UTF8String];
				const char* cLanguage = [lang UTF8String];
				
				// Some dynamic allocations are needed here (will be destroyed with a tts_freeAvailableVoices call)
				char* pName = (char*) malloc(strlen(cName) + 1);
				char* pLanguage = (char*) malloc(strlen(cLanguage) + 1);
				char* pIdentifier = (char*) malloc(strlen(cIdendifier) + 1);

				// Copy strings to the allocated memory
				strcpy(pName, cName);
				strcpy(pLanguage, cLanguage);
				strcpy(pIdentifier, cIdendifier);

				// Update the internal buffer
				tts_availableVoiceData_buffer[index].name = (const char*) pName;
				tts_availableVoiceData_buffer[index].language = (const char*) pLanguage;
				tts_availableVoiceData_buffer[index].identifier = (const char*) pIdentifier;

				index += 1;
			}
		#endif
		}

		void tts_freeAvailableVoices() {
			for (int i=0; i<tts_availableVoiceData_count; i++) {
				free((char*) tts_availableVoiceData_buffer[i].name);
				free((char*) tts_availableVoiceData_buffer[i].language);
				free((char*) tts_availableVoiceData_buffer[i].identifier);
			}
			free(tts_availableVoiceData_buffer);
			tts_availableVoiceData_buffer = NULL;
			tts_availableVoiceData_count = 0;
		}

		// just a little local forward declaration
		void tts_initPitch();

		// initiliaze the speech engine
		bool tts_init() {
			tts_initialized = false;
		#if defined(DM_PLATFORM_IOS)			// DEBUG BRUNO
			return tts_initialized;
		#endif 
			pEngine = (Engine*) malloc(sizeof(Engine));
			if (!pEngine)
				return tts_initialized;
		    pEngine->currentLocale = pEngine->lastString = @"";
		    pEngine->speechSynthesizer = [[NSSpeechSynthesizer alloc] init];
			tts_allocAvailableVoices();
			tts_initialized = true;
			tts_setVoice(NULL); // set to default voice
			tts_initPitch();
			
			return tts_initialized;
		}
		// finalize the speech engine
		void tts_shutdown() {
			if ( !tts_initialized ) return;
			tts_freeAvailableVoices();
			#if defined(DM_PLATFORM_IOS)
				[pEngine->speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
			#else // MAC OS
				[pEngine->speechSynthesizer stopSpeaking];
			#endif
			[pEngine->speechSynthesizer release];
			pEngine->speechSynthesizer = nil;

			[pEngine->lastString release];
			pEngine->lastString = nil;

			[pEngine->currentLocale release];
			pEngine->currentLocale = nil;

			free(pEngine);
			pEngine = NULL;
		}
		// say something
		void tts_speak(const char* text) {
			if ( !tts_initialized ) return;
			NSString *stringToBeSpoken= [NSString stringWithUTF8String:text];
			#if defined(DM_PLATFORM_IOS)
				AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:stringToBeSpoken];
				utterance.voice = tts_voice;
				utterance.pitchMultiplier = tts_pitch; // within the range of 0.5 to 2.0 (default 1.0)
				utterance.rate = tts_rate;	// within the range of ? to ?
				utterance.volume = tts_volume; // within the range of 0.0 to 1.0 (default 1.0)
				[pEngine->speechSynthesizer speakUtterance:utterance];
			#else // MAC OS
				[pEngine->speechSynthesizer startSpeakingString:stringToBeSpoken];
			#endif
		}
		// serialize speaking
		void tts_speakToFile(const char* text, const char* filename) {
			if ( !tts_initialized ) return;
			#if defined(DM_PLATFORM_OSX)
				NSString *aText = [NSString stringWithUTF8String:text];
				NSString *aFilename = [NSString stringWithUTF8String:filename];
				NSURL *aURL = [[NSURL alloc]initFileURLWithPath:aFilename];
				[pEngine->speechSynthesizer startSpeakingString:aText toURL:aURL];
			#endif
		}
		// stop speaking
		void tts_stop() {
			if ( !tts_initialized ) return;
			#if defined(DM_PLATFORM_IOS)
				[pEngine->speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
			#else /* MAC OSX */
				[pEngine->speechSynthesizer stopSpeaking];
				[pEngine->speechSynthesizer setObject:nil
										forProperty:NSSpeechResetProperty
										error:nil];
			#endif
			tts_paused = false;
		}
		// pause speaking
		void tts_pause() {
			if ( !tts_initialized ) return;
			if ( !tts_paused ) {
			#if defined(DM_PLATFORM_IOS)
				[pEngine->speechSynthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
			#else // MAC OS
				[pEngine->speechSynthesizer pauseSpeakingAtBoundary:NSSpeechImmediateBoundary];
			#endif
			tts_paused = true;
			}
		}
		// resume speaking
		void tts_resume() {
			if ( !tts_initialized ) return;
			if ( tts_paused ) {
				[pEngine->speechSynthesizer continueSpeaking];
				tts_paused = false;
			}
		}
		// is speaking
		bool tts_isSpeaking() {
			if ( !tts_initialized ) return false;
			bool result = false;
			result = [pEngine->speechSynthesizer isSpeaking];
			return result;
		}
		// set the speech rate in words per minute
		bool tts_setRate(float rate) {
			if ( !tts_initialized ) return false;
			bool result = true;
			tts_rate = rate;
			if ( tts_rate < 0.0f ) tts_rate = 0.0f;
			if ( tts_rate > 2.0f ) tts_rate = 2.0f;
			#if defined(DM_PLATFORM_OSX)	
				// NSSpeechSynthesizer supports words per minute,
				// Human speech is 180 to 220.
				// Let 200 be the default.
				[pEngine->speechSynthesizer setObject:[NSNumber numberWithInt:tts_rate * 200]
											forProperty:NSSpeechRateProperty
											error:nil];
			#endif
			return result;
		}
		// get the speech rate (words per minute) 
		float tts_getRate() {
			if ( !tts_initialized ) return -1.0f;
			return tts_rate;
		}
		void tts_initPitch() {
			if ( !tts_initialized ) return;
			#if defined(DM_PLATFORM_OSX)
				// get the default pitch (this is an int here)
				NSError* errorCode;
				NSNumber* defaultPitchObj = [pEngine->speechSynthesizer objectForProperty:NSSpeechPitchBaseProperty
																		error:&errorCode];
				tts_basePitch = defaultPitchObj ? [defaultPitchObj intValue] : 48;
			#endif
			tts_setPitch(1.0);
		}

		// set the pitch voice
		bool tts_setPitch(float pitch) {
			if ( !tts_initialized ) return false;
			bool result = true;
			tts_pitch = pitch;
			if ( tts_pitch < 0.0f ) tts_pitch = 0.0f;
			if ( tts_pitch > 2.0f ) tts_pitch = 2.0f;
			#if defined(DM_PLATFORM_OSX)
				// The input is a float from 0.0 to 2.0, with 1.0 being the default.
				// use the default pitch for this voice and modulate it by 50% - 150%.
				int newPitch = (int)(tts_basePitch * (0.5 * tts_pitch + 0.5));
				[pEngine->speechSynthesizer setObject:[NSNumber numberWithInt:newPitch]
											forProperty:NSSpeechPitchBaseProperty
											error:nil];
			#endif
			return result;
		}
		// get the pitch voice
		float tts_getPitch() {
			if ( !tts_initialized ) return -1.0f;
			return tts_pitch;
		}
		// set the volume using a floating point value in the range of 0.0 to 1.0 inclusive
		bool tts_setVolume(float volume) {
			if ( !tts_initialized ) return false;
			bool result = true;
			tts_volume = volume;
			if ( tts_volume < 0.0f ) tts_volume = 0.0f;
			if ( tts_volume > 1.0f ) tts_volume = 1.0f;
			#if defined(DM_PLATFORM_OSX)
				[pEngine->speechSynthesizer setObject:[NSNumber numberWithFloat:tts_volume]
											forProperty:NSSpeechVolumeProperty
											error:nil];
			#endif
			return result;
		}
		// get the volume
		float tts_getVolume() {
			if ( !tts_initialized ) return -1.0f;
			return tts_volume;
		}
		// set the callback to call when these events occur :
		//
		void tts_setCallback(void* func) {
			if ( !tts_initialized ) return;
			tts_callback = func;
		}
		// set the current voice using a string identifier (see tts_getAvailableVoices)
		// if identifier is NULL then set with the first available voice, the default one
		bool tts_setVoice(const char* voiceId) {
			if ( !tts_initialized ) return false;
			bool result = false;
			if (voiceId == NULL && tts_availableVoiceData_count > 0) {
				tts_selectedVoiceData_index = 0;
				voiceId = tts_availableVoiceData_buffer[tts_selectedVoiceData_index].identifier;
				result = true;
			} else {
				for (int i=0; i<tts_availableVoiceData_count; i++) {
					if ( strcmp(tts_availableVoiceData_buffer[i].identifier, voiceId) == 0 ) {
						tts_selectedVoiceData_index = i;
						result = true;
						break;
					}
				}
			}
			if (result) {
				NSString* voice_identifier = [NSString stringWithUTF8String:voiceId];
				#if defined(DM_PLATFORM_IOS)
					tts_voice = [AVSpeechSynthesisVoice voiceWithIdentifier:voice_identifier];
				#else // MAC OS
					[pEngine->speechSynthesizer  setVoice:voice_identifier];
				#endif
			}
			return result;
		}
		// get the current voice
		tts_VoiceData tts_getVoice() {
			if ( !tts_initialized ) return emptyVoiceData;
			if ( tts_selectedVoiceData_index == -1) return emptyVoiceData;
			return tts_availableVoiceData_buffer[tts_selectedVoiceData_index];
		}

		// a pseudo iterator mechanism
		tts_VoiceData* tts_getFirstAvailableVoice() {
			if ( !tts_initialized ) return NULL;
			if ( !tts_availableVoiceData_count ) return NULL;
			tts_availableVoiceData_iter = 0;
			return tts_availableVoiceData_buffer;
		}
		tts_VoiceData* tts_getNextAvailableVoice() {
			if ( !tts_initialized ) return NULL;
			if ( tts_availableVoiceData_iter+1 < tts_availableVoiceData_count) {
				tts_availableVoiceData_iter += 1;
			} else { // reached the end...
				return NULL;
			}
			return &tts_availableVoiceData_buffer[tts_availableVoiceData_iter];
		}
	#endif
#endif