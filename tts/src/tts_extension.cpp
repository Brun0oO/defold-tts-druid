// tts_extension.cpp
// Extension lib defines
#define LIB_NAME "TTS"
#define MODULE_NAME "TTS"

// include the Defold SDK
#include <dmsdk/sdk.h>

#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX) // || defined(DM_PLATFORM_ANDROID)
#include "tts_private.h"

static int Speak(lua_State* L)
{
    // The number of expected items to be on the Lua stack
    // once this struct goes out of scope
    DM_LUA_STACK_CHECK(L, 0);

    int nbArgs = lua_gettop(L);
    if (nbArgs != 1) {
        return luaL_error(L, "expecting 1 argument");
    }

    // Check and get parameter string (the first one) from stack
    char* text = (char*)luaL_checkstring(L, 1);

    tts_speak(text);
    // Return 0 item   
    return 0;
}

static int Stop(lua_State* L)
{
    // The number of expected items to be on the Lua stack
    // once this struct goes out of scope
    DM_LUA_STACK_CHECK(L, 0);
    
    tts_stop();
    return 0;
}

static int Pause(lua_State* L)
{
    // The number of expected items to be on the Lua stack
    // once this struct goes out of scope
    DM_LUA_STACK_CHECK(L, 0);
    
    tts_pause();
    return 0;
}

static int Resume(lua_State* L)
{
    // The number of expected items to be on the Lua stack
    // once this struct goes out of scope
    DM_LUA_STACK_CHECK(L, 0);
    
    tts_resume();
    return 0;
}

static int IsSpeaking(lua_State* L)
{
    // The number of expected items to be on the Lua stack
    // once this struct goes out of scope
    DM_LUA_STACK_CHECK(L, 1);
    
    bool result = tts_isSpeaking();
    lua_pushboolean(L, result);
    return 1;
}

static int SpeakToFile(lua_State* L)
{
    // appeler ici la fonction implementée via tts_bridge_interface...
    return 0;
}

static int SetRate(lua_State* L)
{
    // The number of expected items to be on the Lua stack
    // once this struct goes out of scope
    DM_LUA_STACK_CHECK(L, 0);
    
    int nbArgs = lua_gettop(L);
    if (nbArgs != 1) {
        return luaL_error(L, "expecting 1 argument");
    }

    double rate = luaL_checknumber(L, 1) / 200.0f;
    tts_setRate(rate);
    
    return 0;
}
static int GetRate(lua_State* L)
{
    // The number of expected items to be on the Lua stack
    // once this struct goes out of scope
    DM_LUA_STACK_CHECK(L, 1);

    double rate = tts_getRate() * 200.0f;
    lua_pushnumber(L, rate);
    
    return 1;
}
static int SetPitch(lua_State* L)
{
    // The number of expected items to be on the Lua stack
    // once this struct goes out of scope
    DM_LUA_STACK_CHECK(L, 0);

    int nbArgs = lua_gettop(L);
    if (nbArgs != 1) {
        return luaL_error(L, "expecting 1 argument");
    }

    double pitch = luaL_checknumber(L, 1);
    tts_setPitch(pitch);
    return 0;
}
static int GetPitch(lua_State* L)
{
    // The number of expected items to be on the Lua stack
    // once this struct goes out of scope
    DM_LUA_STACK_CHECK(L, 1);

    double pitch = tts_getPitch();
    lua_pushnumber(L, pitch);

    return 1;
}
static int SetVolume(lua_State* L)
{
    // The number of expected items to be on the Lua stack
    // once this struct goes out of scope
    DM_LUA_STACK_CHECK(L, 0);

    int nbArgs = lua_gettop(L);
    if (nbArgs != 1) {
        return luaL_error(L, "expecting 1 argument");
    }

    double volume = luaL_checknumber(L, 1) / 100.0f;
    tts_setVolume(volume);
    return 0;
}

static int GetVolume(lua_State* L)
{
    // The number of expected items to be on the Lua stack
    // once this struct goes out of scope
    DM_LUA_STACK_CHECK(L, 1);

    double volume = tts_getVolume() * 100.0f;
    lua_pushnumber(L, volume);

    return 1;
}
static int SetVoice(lua_State* L)
{
    // The number of expected items to be on the Lua stack
    // once this struct goes out of scope
    DM_LUA_STACK_CHECK(L, 1);

    int nbArgs = lua_gettop(L);
    if (nbArgs != 1) {
        return luaL_error(L, "expecting 1 argument");
    }
    // Check and get parameter string (the first one) from stack
    char* identifier = (char*)luaL_checkstring(L, 1);
    bool result = tts_setVoice(identifier);
    lua_pushboolean(L, result);
    return 1;
}
static int GetVoice(lua_State* L)
{
    // The number of expected items to be on the Lua stack
    // once this struct goes out of scope
    DM_LUA_STACK_CHECK(L, 1);
    tts_VoiceData voiceData = tts_getVoice();
    lua_newtable(L);
    lua_pushstring(L, "identifier");
    lua_pushstring(L, voiceData.identifier);
    lua_settable(L, -3); 
    lua_pushstring(L, "name");
    lua_pushstring(L, voiceData.name);
    lua_settable(L, -3); 
    lua_pushstring(L, "language");
    lua_pushstring(L, voiceData.language);
    lua_settable(L, -3); 
    return 1;
}

static int GetAvailableVoices(lua_State* L)
{
    // The number of expected items to be on the Lua stack
    // once this struct goes out of scope
    DM_LUA_STACK_CHECK(L, 1);

    lua_newtable(L);
    tts_VoiceData* voiceData = tts_getFirstAvailableVoice();
    int count = 0;
    while( voiceData ) {
        count += 1;
        lua_pushnumber( L, count );
        lua_newtable(L);
        lua_pushstring(L, "name");
        lua_pushstring(L, voiceData->name);
        lua_settable(L,-3);
        lua_pushstring(L, "language");
        lua_pushstring(L, voiceData->language);
        lua_settable(L,-3);
        lua_pushstring(L, "identifier");
        lua_pushstring(L, voiceData->identifier);
        lua_settable(L,-3);               
        lua_settable(L,-3);
        voiceData = tts_getNextAvailableVoice();
    }
    return 1;
}

// Functions exposed to Lua
static const luaL_reg Module_methods[] =
{
    {"speak", Speak},
    {"stop", Stop},
    {"pause", Pause},
    {"resume", Resume},
    {"isSpeaking", IsSpeaking},
    {"speakToFile", SpeakToFile},
    {"setRate", SetRate},
    {"getRate", GetRate},
    {"setPitch", SetPitch},
    {"getPitch", GetPitch},
    {"setVolume", SetVolume},
    {"getVolume", GetVolume},
    {"setVoice", SetVoice},
    {"getVoice", GetVoice},
    {"getAvailableVoices", GetAvailableVoices},
    {0, 0}
};

static void LuaInit(lua_State* L)
{
    int top = lua_gettop(L);

    // Register lua names
    luaL_register(L, MODULE_NAME, Module_methods);

    lua_pop(L, 1);
    assert(top == lua_gettop(L));
}

dmExtension::Result AppInitializeTTS(dmExtension::AppParams* params)
{
    dmLogInfo("AppInitializeTTS\n");
    return dmExtension::RESULT_OK;
}

dmExtension::Result InitializeTTS(dmExtension::Params* params)
{
    // Init Lua
    LuaInit(params->m_L);
    dmLogInfo("Registered %s Extension\n", MODULE_NAME);
    tts_init();
    dmLogInfo("** after tts_init call **\n");
    return dmExtension::RESULT_OK;
}

dmExtension::Result AppFinalizeTTS(dmExtension::AppParams* params)
{
    dmLogInfo("AppFinalizeTTS\n");
    return dmExtension::RESULT_OK;
}

dmExtension::Result FinalizeTTS(dmExtension::Params* params)
{
    dmLogInfo("FinalizeTTS\n");
    tts_shutdown();
    return dmExtension::RESULT_OK;
}

dmExtension::Result OnUpdateTTS(dmExtension::Params* params)
{
    return dmExtension::RESULT_OK;
}

void OnEventTTS(dmExtension::Params* params, const dmExtension::Event* event)
{
    switch(event->m_Event)
    {
        case dmExtension::EVENT_ID_ACTIVATEAPP:
            dmLogInfo("OnEventTTS - EVENT_ID_ACTIVATEAPP\n");
            break;
        case dmExtension::EVENT_ID_DEACTIVATEAPP:
            dmLogInfo("OnEventTTS - EVENT_ID_DEACTIVATEAPP\n");
            break;
        case dmExtension::EVENT_ID_ICONIFYAPP:
            dmLogInfo("OnEventTTS - EVENT_ID_ICONIFYAPP\n");
            break;
        case dmExtension::EVENT_ID_DEICONIFYAPP:
            dmLogInfo("OnEventTTS - EVENT_ID_DEICONIFYAPP\n");
            break;
        default:
            dmLogWarning("OnEventTTS - Unknown event id\n");
            break;
    }
}
#else  // unsupported platforms
static dmExtension::Result AppInitializeTTS(dmExtension::AppParams* params)
{
    dmLogInfo("Registered %s (null) Extension", MODULE_NAME);
    return dmExtension::RESULT_OK;
}

static dmExtension::Result InitializeTTS(dmExtension::Params* params)
{
    return dmExtension::RESULT_OK;
}

static dmExtension::Result UpdateTTS(dmExtension::Params* params)
{
    return dmExtension::RESULT_OK;
}

static dmExtension::Result AppFinalizeTTS(dmExtension::AppParams* params)
{
    return dmExtension::RESULT_OK;
}

static dmExtension::Result FinalizeCamera(dmExtension::Params* params)
{
    return dmExtension::RESULT_OK;
}

static dmExtension::Result OnUpdateTTS(dmExtension::Params* params)
{
    dmLogInfo("OnUpdateTTS\n");
    return dmExtension::RESULT_OK;
}

static void OnEventTTS(dmExtension::Params* params, const dmExtension::Event* event)
{
    switch(event->m_Event)
    {
        case dmExtension::EVENT_ID_ACTIVATEAPP:
        dmLogInfo("OnEventTTS - EVENT_ID_ACTIVATEAPP\n");
        break;
        case dmExtension::EVENT_ID_DEACTIVATEAPP:
        dmLogInfo("OnEventTTS - EVENT_ID_DEACTIVATEAPP\n");
        break;
        case dmExtension::EVENT_ID_ICONIFYAPP:
        dmLogInfo("OnEventTTS - EVENT_ID_ICONIFYAPP\n");
        break;
        case dmExtension::EVENT_ID_DEICONIFYAPP:
        dmLogInfo("OnEventTTS - EVENT_ID_DEICONIFYAPP\n");
        break;
        default:
        dmLogWarning("OnEventTTS - Unknown event id\n");
        break;
    }
}
#endif // platforms
// Defold SDK uses a macro for setting up extension entry points:
//
// DM_DECLARE_EXTENSION(symbol, name, app_init, app_final, init, update, on_event, final)

// TTS is the C++ symbol that holds all relevant extension data.
// It must match the name field in the `ext.manifest`
DM_DECLARE_EXTENSION(TTS, LIB_NAME, AppInitializeTTS, AppFinalizeTTS, InitializeTTS, OnUpdateTTS, OnEventTTS, FinalizeTTS)
