#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <clientprefs>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#include <outbreak>
#include <stamm>
#include <emitsoundany>
#include <autoexecconfig>
#include <futuristicgrenades>
#include <verstecken>
#include <krieg>
#include <gohan>

#undef REQUIRE_PLUGIN
#include <jail>
#include <knockout>
#include <lastrequest>

#pragma newdecls required

#define DICE_SOUND       "outbreak/jail/dice/dice.mp3"
#define NEGATIVE_SOUND   "outbreak/jail/dice/negative.mp3"
#define NEUTRAL_SOUND    "outbreak/jail/dice/neutral.mp3"
#define POSITIVE_SOUND   "outbreak/jail/dice/positive.mp3"
#define JIHAD_SOUND      "outbreak/jail/dice/jihad/jihad.mp3"
#define EXPLOSION_SOUND  "outbreak/jail/dice/jihad/explosion.mp3"

// Auto Dice
Handle g_hAutoCTDice = null;
bool g_bAutoCTDice[MAXPLAYERS + 1] = { false, ... };
Handle g_hAutoT1Dice = null;
bool g_bAutoT1Dice[MAXPLAYERS + 1] = { false, ... };
Handle g_hAutoT2Dice = null;
bool g_bAutoT2Dice[MAXPLAYERS + 1] = { false, ... };

int g_iClip1 = -1;

int g_iCount[MAXPLAYERS + 1] =  { 0, ... };
int g_iNoclipCounter[MAXPLAYERS + 1] = {5, ...};
int g_iFroggyAir[MAXPLAYERS + 1] =  { 0, ... };

bool g_bInWater[MAXPLAYERS + 1] = {false, ...};
bool g_bFroggyjump[MAXPLAYERS + 1] =  { false, ... };
bool g_bFroggyPressed[MAXPLAYERS + 1] =  { false, ... };
bool g_bLongjump[MAXPLAYERS + 1] =  { false, ... };
bool g_bBhop[MAXPLAYERS + 1] =  { false, ... };
bool g_bAssassine[MAXPLAYERS + 1] =  { false, ... };
bool g_bTollpatsch[MAXPLAYERS + 1] =  { false, ... };
bool g_bLose[MAXPLAYERS + 1] =  { false, ... };
bool g_bMirrorMovement[MAXPLAYERS + 1] =  { false, ... };
bool g_bZombie[MAXPLAYERS + 1] =  { false, ... };
bool g_bDecoy[MAXPLAYERS + 1] =  { false, ... };
bool g_bJihad[MAXPLAYERS + 1] =  { false, ... };
bool g_bNoFallDamage[MAXPLAYERS + 1] =  { false, ... };
bool g_bRentner[MAXPLAYERS + 1] =  { false, ... };
bool g_bAWP[MAXPLAYERS + 1] = { false, ... };
int g_iLover[MAXPLAYERS + 1] = { -1, ... };
Handle g_hDrugsTimer[MAXPLAYERS + 1] = { null, ... };
Handle g_hDrunkTimer[MAXPLAYERS + 1] = { null, ... };
Handle g_hDelayedSlay[MAXPLAYERS + 1] = { null, ... };
DecoyMode g_dmFuturistic[MAXPLAYERS + 1] = { DecoyMode_Normal, ... };
float g_fDamage[MAXPLAYERS + 1] = {0.0, ...};
bool g_bMoreDamage[MAXPLAYERS + 1] = {false, ...};
bool g_bLessDamage[MAXPLAYERS + 1] = {false, ...};
bool g_bHeadshot[MAXPLAYERS + 1] = {false, ...};
bool g_bRespawn[MAXPLAYERS + 1] = {false, ...};
Handle g_hBitchSlap[MAXPLAYERS + 1] = { null, ... };
int g_iBSCount[MAXPLAYERS + 1] = { -1, ... };
Handle g_hLowGravity[MAXPLAYERS + 1] =  { null, ... };
Handle g_hHighGravity[MAXPLAYERS + 1] =  { null, ... };
Handle g_hNoclip[MAXPLAYERS + 1] =  { null, ... };

Database g_dDB = null;

bool g_bHosties = false;
bool g_bJail = false;
bool g_bKnockout = false;

// Pots
bool g_bReady = false;
ArrayList g_aT1Pot = null;
ArrayList g_aT2Pot = null;
ArrayList g_aCTPot = null;

bool g_bBusy[MAXPLAYERS + 1] = {false, ...};
Handle g_hDiceTimer[MAXPLAYERS + 1] = {null, ...};

ConVar g_cDebug = null;

bool g_bLateLoad = false;

enum struct DiceOption {
    char Name[32];
    bool Delete;
    bool Debug;
}

#include "dice/sql.sp"
#include "dice/functions.sp"
#include "dice/configs.sp"
#include "dice/options.sp"
#include "dice/autodice.sp"

public Plugin myinfo =
{
    name = "Dice - Dice that includes CT and 2 T dices", 
    author = "Bara", 
    description = "", 
    version = "1.0", 
    url = "github.com/Bara"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("Dice_IsClientAssassine", Native_IsAssassine);
    CreateNative("Dice_HasClientBhop", Native_HasClientBhop);
    CreateNative("Dice_LoseAll", Native_LoseAll);
    
    RegPluginLibrary("dice");

    g_bLateLoad = late;
    
    return APLRes_Success;
}

public void OnPluginStart()
{
    RegConsoleCmd("sm_w", Command_Dice);
    RegConsoleCmd("sm_autow", Command_AutoDice);
    
    HookEvent("player_jump", Event_PlayerJump);
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
    HookEvent("round_start", Event_RoundStart);
    HookEvent("round_end", Event_RoundEnd);
    HookEvent("smokegrenade_detonate", Event_SmokeDetonate, EventHookMode_Post);
    HookEvent("decoy_started", Event_DecoyStarted, EventHookMode_Pre);

    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile("plugin.dice");
    g_cDebug = AutoExecConfig_CreateConVar("dice_debug", "0", "Enable/Disable debug mode for dice", _, true, 0.0, true, 1.0);
    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();

    CSetPrefix("{green}[Dice]{default}");

    g_bHosties = LibraryExists("hosties");
    g_bJail = LibraryExists("jail");
    g_bKnockout = LibraryExists("knockout");

    if (g_bLateLoad)
    {
        g_bReady = ReadDiceOptions();
    }

    g_iClip1 = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
    if (g_iClip1 == -1)
    {
        SetFailState("Unable to find offset for clip.");
    }

    g_hAutoCTDice = RegClientCookie("dice_auto_ct_dice", "Auto for T-Dice", CookieAccess_Private);
    g_hAutoT1Dice = RegClientCookie("dice_auto_t1_dice", "Auto for T-Dice", CookieAccess_Private);
    g_hAutoT2Dice = RegClientCookie("dice_auto_t2_dice", "Auto for T-Dice", CookieAccess_Private);

    LoopClients(i)
    {
        if (!AreClientCookiesCached(i))
        {
            continue;
        }
        
        SDKHook(i, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
        OnClientCookiesCached(i);
    }
}

public void OnClientCookiesCached(int client)
{
    char sBuffer[4];

    GetClientCookie(client, g_hAutoCTDice, sBuffer, sizeof(sBuffer));
    g_bAutoCTDice[client] = view_as<bool>(StringToInt(sBuffer));

    GetClientCookie(client, g_hAutoT1Dice, sBuffer, sizeof(sBuffer));
    g_bAutoT1Dice[client] = view_as<bool>(StringToInt(sBuffer));

    GetClientCookie(client, g_hAutoT2Dice, sBuffer, sizeof(sBuffer));
    g_bAutoT2Dice[client] = view_as<bool>(StringToInt(sBuffer));
}

public void OnAllPluginsLoaded()
{
    if (LibraryExists("hosties"))
    {
        g_bHosties = true;
    }
    else if (LibraryExists("jail"))
    {
        g_bJail = true;
    }
    else if (LibraryExists("knockout"))
    {
        g_bKnockout = true;
    }

    if (!STAMM_IsAvailable()) 
    {
        SetFailState("Can't Load Feature, Stamm is not installed!");
    }

    STAMM_RegisterFeature("VIP SecondDice");
}

public int STAMM_OnClientRequestFeatureInfo(int client, int block, Handle &array)
{
    PushArrayString(array, "Zugang zum 2. T-Würfel");
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "hosties"))
    {
        g_bHosties = true;
    }
    else if (StrEqual(name, "jail"))
    {
        g_bJail = true;
    }
    else if (StrEqual(name, "knockout"))
    {
        g_bKnockout = true;
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if (StrEqual(name, "hosties"))
    {
        g_bHosties = false;
    }
    else if (StrEqual(name, "jail"))
    {
        g_bJail = false;
    }
    else if (StrEqual(name, "knockout"))
    {
        g_bKnockout = false;
    }
}

public void OnMapStart()
{
    PrecacheSoundAny(DICE_SOUND);
    AddFileToDownloadsTable("sound/" ... DICE_SOUND);

    PrecacheSoundAny(NEGATIVE_SOUND);
    AddFileToDownloadsTable("sound/" ... NEGATIVE_SOUND);

    PrecacheSoundAny(NEUTRAL_SOUND);
    AddFileToDownloadsTable("sound/" ... NEUTRAL_SOUND);

    PrecacheSoundAny(POSITIVE_SOUND);
    AddFileToDownloadsTable("sound/" ... POSITIVE_SOUND);

    PrecacheSoundAny(JIHAD_SOUND, true);
    AddFileToDownloadsTable("sound/" ... JIHAD_SOUND);

    PrecacheSoundAny(EXPLOSION_SOUND, true);
    AddFileToDownloadsTable("sound/" ... EXPLOSION_SOUND);

    // g_bReady = false;

    // Create hostage zone to fix for shield option
    int iEntity = -1;
    if((iEntity = FindEntityByClassname(iEntity, "func_hostage_rescue")) == -1) {
        int iHostageRescueEnt = CreateEntityByName("func_hostage_rescue");
        DispatchKeyValue(iHostageRescueEnt, "targetname", "fake_hostage_rescue");
        DispatchKeyValue(iHostageRescueEnt, "origin", "-3141 -5926 -5358");
        DispatchSpawn(iHostageRescueEnt);
    }
}

public int Native_IsAssassine(Handle plugin, int numParams)
{
    return g_bAssassine[GetNativeCell(1)];
}

public int Native_HasClientBhop(Handle plugin, int numParams)
{
    return g_bBhop[GetNativeCell(1)];
}

public int Native_LoseAll(Handle plugin, int numParams)
{
    return g_bLose[GetNativeCell(1)];
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

public void OnClientDisconnect(int client)
{
    ResetDice(client);
}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int HitGroup)
{
    if (!IsClientValid(victim))
    {
        return Plugin_Continue;
    }

    if (g_bNoFallDamage[victim] && damagetype & DMG_FALL)
    {
        return Plugin_Handled;
    }

    if (IsClientValid(attacker))
    {
        if (g_bHosties)
        {
            if (IsClientInLastRequest(attacker) || IsClientInLastRequest(victim))
            {
                return Plugin_Continue;
            }
        }

        if (g_bTollpatsch[attacker])
        {
            bool bDamage = view_as<bool>(GetRandomInt(0, 1));

            if (!bDamage)
            {
                damage = 0.0;
                return Plugin_Changed;
            }
        }
        
        if (g_bMoreDamage[attacker])
        {
            damage *= g_fDamage[attacker];
            return Plugin_Changed;
        }
        
        if (g_bLessDamage[victim])
        {
            damage /= g_fDamage[victim];
            return Plugin_Changed;
        }
        
        if (g_bHeadshot[victim] && damagetype & CS_DMG_HEADSHOT)
        {
            return Plugin_Handled;
        }

        if (g_bAWP[attacker])
        {
            int iEntity = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");

            if (!IsValidEntity(iEntity))
            {
                return Plugin_Continue;
            }

            char sClass[32];
            GetEntityClassname(iEntity, sClass, sizeof(sClass));

            if (StrContains(sClass, "awp", false) != -1)
            {
                g_bAWP[attacker] = false;

                damage = 0.0;
                return Plugin_Changed;
            }
        }
    }
    return Plugin_Continue;
}

public Action FGrenades_OnSwitchMode(int client, DecoyMode previousmode, DecoyMode &newmode, int weapon)
{
    if (newmode != g_dmFuturistic[client])
    {
        newmode = g_dmFuturistic[client];
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

public Action Command_Dice(int client, int args)
{
    if (Outbreak_IsHideActive() || IsWarActive())
    {
        CReplyToCommand(client, "Dice ist im %s deaktiviert.", Outbreak_IsHideActive() ? "Hide&Seek" : "Krieg");
        return Plugin_Handled;
    }

    if (!g_bReady)
    {
        CReplyToCommand(client, "Die Würfel sind noch nicht gezinkt.");
        return Plugin_Handled;
    }

    char sOption[32];
    if (g_cDebug.BoolValue)
    {
        GetCmdArg(1, sOption, sizeof(sOption));

        bool bReset = false;
        if (!CheckCommandAccess(client, "sm_admin", ADMFLAG_ROOT, true))
        {
            sOption[0] = '\0';
        }

        if (bReset || strlen(sOption) < 2)
        {
            sOption[0] = '\0';
        }
    }

    if (IsClientValid(client))
    {
        if (IsPlayerAlive(client))
        {
            if ((g_bJail && Jail_IsClientCapitulate(client)) || (g_bKnockout && IsClientKnockout(client)))
            {
                return Plugin_Handled;
            }
            
            int team = GetClientTeam(client);

            bool bAccess = false;

            if (team == CS_TEAM_CT && g_iCount[client] == 0)
            {
                bAccess = true;
            }
            else if (team == CS_TEAM_T)
            {
                if (g_iCount[client] == 0)
                {
                    bAccess = true;
                }
                else if (g_iCount[client] == 1)
                {
                    if (STAMM_HaveClientFeature(client))
                    {
                        bAccess = true;
                    }
                    else
                    {
                        CReplyToCommand(client, "Sie haben nicht den nötigen Stamm Rank um ein zweites mal zu würfeln.");
                    }
                }
            }
            
            if (bAccess)
            {
                if (!g_bBusy[client] && g_hDiceTimer[client] == null)
                {
                    g_bBusy[client] = true;

                    EmitSoundToClientAny(client, DICE_SOUND);

                    Panel panel = new Panel();
                    panel.SetTitle("Der Würfel rollt...");
                    panel.DrawText("(Glücksspiel kann süchtig machen!)");
                    panel.Send(client, Panel_Nothing, 3);
                    delete panel;

                    DataPack pack = new DataPack();
                    pack.WriteCell(GetClientUserId(client));
                    pack.WriteCell(team);
                    pack.WriteString(sOption);
                    g_hDiceTimer[client] = CreateTimer(2.0, Timer_Dice, pack);
                }
                else
                {
                    CReplyToCommand(client, "Der Würfel rollt gerade...");
                }
            }
            else
            {
                CReplyToCommand(client, "Du hast schon %s%dx %sgewürfelt.", SPECIAL, g_iCount[client], TEXT);
            }
        }
        else
        {
            CReplyToCommand(client, "Das macht kein Sinn...");
        }
        
    }
    
    return Plugin_Handled;
}

public Action Timer_Dice(Handle timer, DataPack pack)
{
    pack.Reset();
    int client = GetClientOfUserId(pack.ReadCell());
    int team = pack.ReadCell();
    char sOption[32];
    pack.ReadString(sOption, sizeof(sOption));
    delete pack;

    if (IsClientValid(client))
    {
        if (IsPlayerAlive(client))
        {
            // Types: 0 - Negative, 1 - Neutral, 2 - Positive
            int type = -1;

            Panel panel = new Panel();

            if (g_iCount[client] == 0)
            {
                if (team == CS_TEAM_T)
                {
                    g_iCount[client]++;

                    int iIndex = GetRandomInt(0,  g_aT1Pot.Length - 1);

                    DiceOption Option;
                    g_aT1Pot.GetArray(iIndex, Option, sizeof(Option));

                    int iCount = 0;

                    for (int i = 0; i < g_aT1Pot.Length; i++)
                    {
                        DiceOption tmp;
                        g_aT1Pot.GetArray(i, tmp, sizeof(tmp));

                        if (StrEqual(tmp.Name, Option.Name, false))
                        {
                            iCount++;
                        }
                    }

                    float fChance = float(g_aT1Pot.Length) / float(100) * float (iCount);

                    if (Option.Delete)
                    {
                        g_aT1Pot.Erase(iIndex);
                    }

                    g_aT1Pot.Sort(Sort_Random, Sort_Integer);

                    if (strlen(sOption) > 2)
                    {
                        strcopy(Option.Name, sizeof(DiceOption::Name), sOption);
                        Option.Debug = true;
                    }

                    type = GiveDiceOption(client, Option, CS_TEAM_T, 1, panel, fChance);
                }
                else if (team == CS_TEAM_CT)
                {
                    g_iCount[client]++;

                    int iIndex = GetRandomInt(0,  g_aCTPot.Length - 1);

                    DiceOption Option;
                    g_aCTPot.GetArray(iIndex, Option, sizeof(Option));

                    int iCount = 0;

                    for (int i = 0; i < g_aCTPot.Length; i++)
                    {
                        DiceOption tmp;
                        g_aCTPot.GetArray(i, tmp, sizeof(tmp));

                        if (StrEqual(tmp.Name, Option.Name, false))
                        {
                            iCount++;
                        }
                    }

                    float fChance = float(g_aCTPot.Length) / float(100) * float (iCount);

                    if (Option.Delete)
                    {
                        g_aCTPot.Erase(iIndex);
                    }

                    g_aCTPot.Sort(Sort_Random, Sort_Integer);

                    if (strlen(sOption) > 2)
                    {
                        strcopy(Option.Name, sizeof(DiceOption::Name), sOption);
                        Option.Debug = true;
                    }

                    type = GiveDiceOption(client, Option, CS_TEAM_CT, 1, panel, fChance);
                }
            }
            else
            {
                if (GetClientTeam(client) == CS_TEAM_T)
                {
                    g_iCount[client]++;

                    int iIndex = GetRandomInt(0,  g_aT2Pot.Length - 1);

                    DiceOption Option;
                    g_aT2Pot.GetArray(iIndex, Option, sizeof(Option));

                    int iCount = 0;

                    for (int i = 0; i < g_aT2Pot.Length; i++)
                    {
                        DiceOption tmp;
                        g_aT2Pot.GetArray(i, tmp, sizeof(tmp));

                        if (StrEqual(tmp.Name, Option.Name, false))
                        {
                            iCount++;
                        }
                    }

                    float fChance = float(g_aT2Pot.Length) / float(100) * float (iCount);

                    if (Option.Delete)
                    {
                        g_aT2Pot.Erase(iIndex);
                    }

                    g_aT2Pot.Sort(Sort_Random, Sort_Integer);

                    if (strlen(sOption) > 2)
                    {
                        strcopy(Option.Name, sizeof(DiceOption::Name), sOption);
                        Option.Debug = true;
                    }

                    type = GiveDiceOption(client, Option, CS_TEAM_T, 2, panel, fChance);
                }
            }

            panel.Send(client, Panel_Nothing, 4);
            delete panel;

            if (type == 0)
            {
                EmitSoundToClientAny(client, NEGATIVE_SOUND);
            }
            else if (type == 1)
            {
                EmitSoundToClientAny(client, NEUTRAL_SOUND);
            }
            else if (type == 2)
            {
                EmitSoundToClientAny(client, POSITIVE_SOUND);
            }

            if (team == CS_TEAM_T && g_iCount[client] == 1 && g_bAutoT2Dice[client])
            {
                CPrintToChat(client, "Dein 2. Würfel rollt in 3 Sekunden...");
                CreateTimer(3.0, Timer_AutoDice, GetClientUserId(client));
            }
        }
        else
        {
            CPrintToChat(client, "Das macht keinen Sinn mehr...");
        }

        g_bBusy[client] = false;
        g_hDiceTimer[client] = null;
    }

    return Plugin_Stop;
}

// Events
public Action Event_PlayerJump(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if (IsClientValid(client) && IsPlayerAlive(client) && g_bLongjump[client])
    {
        Longjump(client);
    }

    return Plugin_Handled;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{

    if (GetAliveTPlayers() == 1 && GetAliveCTPlayers() >= 1)
    {
        LoopClients(client)
        {
            if (IsPlayerAlive(client))
            {
                SetEntProp(client, Prop_Send, "m_ArmorValue", 0, 1);
            }
        }
    }

    int client = GetClientOfUserId(event.GetInt("userid"));

    if (!IsClientValid(client))
    {
        return Plugin_Continue;
    }

    LoopClients(i)
    {
        if (IsClientInGame(i) && IsPlayerAlive(i) && g_iLover[i] == client)
        {
            CPrintToChat(i, "Dein Liebling ist gefallen, dein Herz gebrochen und nun fällst auch du.");
            ForcePlayerSuicide(i);
        }
    }

    if (GetAliveTPlayers() >= 1 && GetAliveCTPlayers() >= 1)
    {
        if (g_bRespawn[client])
        {
            if (GetRandomInt(1, 2) == 1)
            {
                CPrintToChat(client, "Du hast durch den Würfel eine 2. Chance verdient! Respawn in 2 Sekunden...");
                CreateTimer(2.0, Timer_RespawnPlayer, GetClientUserId(client));
            }
        }
    }

    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    char sWeapon[32];
    event.GetString("weapon", sWeapon, sizeof(sWeapon));
    
    if (IsClientValid(attacker))
    {
        if (g_bAssassine[attacker] && (StrContains(sWeapon, "awp", false) == -1))
        {
            event.BroadcastDisabled = true;
            return Plugin_Changed;
        }
    }

    return Plugin_Continue;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (IsClientValid(client))
    {
        CreateTimer(0.5, Timer_AutoDice, GetClientUserId(client));

        SetEntityGravity(client, 1.0);
        
        ResetDice(client);
    }

    return Plugin_Handled;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    g_bReady = ReadDiceOptions();

    return Plugin_Continue;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    LoopClients(client)
    {
        if (IsPlayerAlive(client))
        {
            SetEntProp(client, Prop_Send, "m_ArmorValue", 0, 1);
        }
    }

    return Plugin_Handled;
}

public Action Event_SmokeDetonate(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    int entity = event.GetInt("entityid");
    
    if (!IsClientValid(client) || !IsValidEntity(entity))
    {
        return Plugin_Continue;
    }
    
    DataPack pack = new DataPack();
    CreateDataTimer(1.0, Timer_CheckPlayers, pack, TIMER_FLAG_NO_MAPCHANGE);
    pack.WriteCell(GetClientUserId(client));
    pack.WriteCell(EntIndexToEntRef(entity));
    
    return Plugin_Continue;
}

public Action Event_DecoyStarted(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    int entity = event.GetInt("entityid");

    if (!IsClientValid(client))
    {
        return Plugin_Continue;
    }

    FGrenades_SwitchMode(client, DecoyMode_Normal);
    
    if (!g_bDecoy[client] || !IsValidEntity(entity))
    {
        return Plugin_Continue;
    }
    
    AcceptEntityInput(entity, "kill");

    float fOldPos[3];
    GetClientAbsOrigin(client, fOldPos);

    float fPos[3];
    fPos[0] = event.GetFloat("x");
    fPos[1] = event.GetFloat("y");
    fPos[2] = (event.GetFloat("z") + 5.0);

    TeleportEntity(client, fPos, NULL_VECTOR, NULL_VECTOR);

    bool stuck = WillClientStuck(client);

    if (stuck)
    {
        TeleportEntity(client, fOldPos, NULL_VECTOR, NULL_VECTOR);
        CPrintToChat(client, "Du wurdest zurück teleportiert, weil du sonst stucken würdest.");
    }

    g_bDecoy[client] = false;
    
    return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    if (IsClientValid(client) && IsPlayerAlive(client))
    {
        if (g_bJihad[client])
        {
            if (buttons & IN_USE)
            {
                int iEntity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
            
                if (!IsValidEntity(iEntity))
                {
                    return Plugin_Continue;
                }

                char sClassname[32];
                GetEntityClassname(iEntity, sClassname, sizeof(sClassname));

                if (StrContains(sClassname, "c4", false) == -1)
                {
                    return Plugin_Continue;
                }

                StartJihad(client);
                g_bJihad[client] = false;
            }
        }

        if (g_bRentner[client])
        {
            if (buttons & IN_JUMP)
            {
                if (GetEntityFlags(client) & FL_ONGROUND && GetEntityMoveType(client) != MOVETYPE_LADDER)
                {
                    buttons &= ~IN_JUMP;
                }
            }
        }

        if (g_bFroggyjump[client])
        {
            if (GetEntityFlags(client) & FL_ONGROUND)
            {
                g_iFroggyAir[client] = 0;
                g_bFroggyPressed[client] = false;
            }
            else
            {
                if (buttons & IN_JUMP)
                {
                    if (!g_bFroggyPressed[client])
                    {
                        if (g_iFroggyAir[client]++ == 1)
                        {
                            Froggyjump(client);
                        }
                    }
                    
                    g_bFroggyPressed[client] = true;
                }
                else
                {
                    g_bFroggyPressed[client] = false;
                }
            }
        }
        
        if (g_bBhop[client])
        {
            if (buttons & IN_JUMP)
            {
                if (!(GetEntityMoveType(client) & MOVETYPE_LADDER))
                {
                    SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
                    
                    if (!(GetEntityFlags(client) & FL_ONGROUND))
                    {
                        buttons &= ~IN_JUMP;
                    }
                }
            }
        }

        if (g_bMirrorMovement[client])
        {
            vel[1] = -vel[1];

            if (buttons & IN_MOVELEFT) {
                buttons &= ~IN_MOVELEFT;
                buttons |= IN_MOVERIGHT;
            } else if (buttons & IN_MOVERIGHT) {
                buttons &= ~IN_MOVERIGHT;
                buttons |= IN_MOVELEFT;
            }

            vel[2] = -vel[2];

            if (buttons & IN_DUCK) {
                buttons &= ~IN_DUCK;
                buttons |= IN_JUMP;
            } else if (buttons & IN_JUMP) {
                buttons &= ~IN_JUMP;
                buttons |= IN_DUCK;
            }

            vel[0] = -vel[0];

            if (buttons & IN_FORWARD) {
                buttons &= ~IN_FORWARD;
                buttons |= IN_BACK;
            } else if (buttons & IN_BACK) {
                buttons &= ~IN_BACK;
                buttons |= IN_FORWARD;
            }
        }

        if (g_bZombie[client])
        {
            if (buttons & IN_JUMP)
            {
                if (GetEntityFlags(client) & FL_ONGROUND && GetEntityMoveType(client) != MOVETYPE_LADDER)
                {
                    buttons &= ~IN_JUMP;
                }
            }
            
            if (!(buttons & IN_DUCK))
            {
                buttons ^= IN_DUCK;
            }
            
            return Plugin_Changed;
        }
        
        // Remove fire with water contact
        if (GetEntityFlags(client) & FL_INWATER)
        {
            int iFire = GetEntPropEnt(client, Prop_Data, "m_hEffectEntity");
    
            if (IsValidEdict(iFire))
            {
                SetEntPropFloat(iFire, Prop_Data, "m_flLifetime", 0.0);
            }

            if (g_hHighGravity[client] != null)
            {
                SetEntityGravity(client, 1.0);
                g_bInWater[client] = true;
            }
        }
        else if (g_bInWater[client] && GetEntityFlags(client) & FL_ONGROUND || GetEntityFlags(client) & FL_DUCKING)
        {
            CreateTimer(0.5, Timer_ResetInWater, GetClientUserId(client));
        }
    }
    
    return Plugin_Changed;
}
