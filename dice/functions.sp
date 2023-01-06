void ResetDice(int client)
{
    g_iCount[client] = 0;
    g_iNoclipCounter[client] = 5;
    g_iFroggyAir[client] = 0;
    
    g_bInWater[client] = false;
    g_bFroggyjump[client] = false;
    g_bFroggyPressed[client] = false;
    g_bLongjump[client] = false;
    g_bBhop[client] = false;
    g_bAssassine[client] = false;
    g_bTollpatsch[client] = false;
    g_bLose[client] = false;
    g_bMirrorMovement[client] = false;
    g_bZombie[client] = false;
    g_bDecoy[client] = false;
    g_bJihad[client] = false;
    g_bNoFallDamage[client] = false;
    g_bRentner[client] = false;
    g_dmFuturistic[client] = DecoyMode_Normal;
    g_fDamage[client] = 0.0;
    g_bMoreDamage[client] = false;
    g_bLessDamage[client] = false;
    g_bHeadshot[client] = false;
    g_bRespawn[client] = false;
    g_bBusy[client] = false;
    g_bAWP[client] = false;
    g_iLover[client] = -1;

    if (IsClientValid(client))
    {
        if (IsPlayerAlive(client))
        {
            SetEntityMoveType(client, MOVETYPE_WALK);
            SetEntityRenderMode(client, RENDER_TRANSCOLOR);
            SetEntityRenderColor(client, 255, 255, 255);
        }

        SetGohanMode(client, false);
        FGrenades_SwitchMode(client, DecoyMode_Normal);
        ResetBitchSlap(client);

        delete g_hDrugsTimer[client];
        delete g_hDelayedSlay[client];
        delete g_hNoclip[client];
        delete g_hLowGravity[client];
        delete g_hHighGravity[client];
        delete g_hDiceTimer[client];
        g_hDrunkTimer[client] = null;
    }
}

void SetHealth(int client, int hp, bool addHP)
{
    int health = GetClientHealth(client);
    
    if (addHP)
    {
        // Plus HP
        SetEntityHealth(client, health + hp);
    }
    else
    {
        // Minus HP
        health -= hp;
        
        if (health <= 0)
        {
            ForcePlayerSuicide(client);
        }
        else
        {
            SetEntityHealth(client, health);
        }
    }
}

void Froggyjump(int client)
{
    float velocity[3];
    float velocity0;
    float velocity1;
    float velocity2;
    float velocity2_new;

    velocity0 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
    velocity1 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
    velocity2 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");

    velocity2_new = 260.0;

    if (velocity2 < 150.0)
    {
        velocity2_new = 270.0;
    }

    if (velocity2 < 100.0)
    {
        velocity2_new = 300.0;
    }

    if (velocity2 < 50.0)
    {
        velocity2_new = 330.0;
    }

    if (velocity2 < 0.0)
    {
        velocity2_new = 380.0;
    }

    if (velocity2 < -50.0)
    {
        velocity2_new = 400.0;
    }

    if (velocity2 < -100.0)
    {
        velocity2_new = 430.0;
    }

    if (velocity2 < -150.0)
    {
        velocity2_new = 450.0;
    }

    if (velocity2 < -200.0)
    {
        velocity2_new = 470.0;
    }


    velocity[0] = velocity0 * 0.1;
    velocity[1] = velocity1 * 0.1;
    velocity[2] = velocity2_new;
    
    SetEntPropVector(client, Prop_Send, "m_vecBaseVelocity", velocity);
}

void Longjump(int client)
{
    float velocity[3];
    float velocity0;
    float velocity1;
    
    velocity0 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
    velocity1 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
    
    velocity[0] = (7.0 * velocity0) * (1.0 / 4.1);
    velocity[1] = (7.0 * velocity1) * (1.0 / 4.1);
    velocity[2] = 0.0;
    
    SetEntPropVector(client, Prop_Send, "m_vecBaseVelocity", velocity);
}

bool IsClientStuck(int client)
{
    float vOrigin[3], vMins[3], vMaxs[3];

    GetClientAbsOrigin(client, vOrigin);

    GetEntPropVector(client, Prop_Send, "m_vecMins", vMins);
    GetEntPropVector(client, Prop_Send, "m_vecMaxs", vMaxs);
    
    TR_TraceHullFilter(vOrigin, vOrigin, vMins, vMaxs, MASK_ALL, FilterOnlyPlayers, client);

    return TR_DidHit();
}

public bool FilterOnlyPlayers(int entity, int contentsMask, any data)
{
    if (entity != data && IsClientValid(entity) && IsClientValid(data))
    {
        return false;
    }
    else if (entity != data)
    {
        return true;
    }
    else
    {
        return false;
    }
}

float GetClientSpeed(int client)
{
    return GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
}

float SetClientSpeed(int client, float speed)
{
    SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", speed);

    return GetClientSpeed(client);
}

public void Frame_GiveTaser(any userid)
{
    int client = GetClientOfUserId(userid);

    if (IsClientValid(client))
    {
        GivePlayerItem(client, "weapon_taser");
    }
}

bool WillClientStuck(int client)
{
    float vOrigin[3];
    float vMins[3];
    float vMaxs[3];

    GetClientAbsOrigin(client, vOrigin);
    GetEntPropVector(client, Prop_Send, "m_vecMins", vMins);
    GetEntPropVector(client, Prop_Send, "m_vecMaxs", vMaxs);

    TR_TraceHullFilter(vOrigin, vOrigin, vMins, vMaxs, MASK_ALL, OnlyPlayers, client);

    return TR_DidHit();
}

public bool OnlyPlayers(int entity, int contentsMask, any data)
{
    if (entity != data && entity > 0 && entity <= MaxClients)
    {
        return true;
    }
    return false;
}


public Action Timer_ResetInWater(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);

    if (IsClientValid(client))
    {
        g_bInWater[client] = false;
        
        if (IsPlayerAlive(client) && g_hHighGravity[client] != null)
        {
            SetEntityGravity(client, 1.8);
        }
    }

    return Plugin_Stop;
}

public Action Timer_ResetInvisible(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);

    if (IsClientValid(client))
    {
        SetEntityRenderMode(client, RENDER_TRANSCOLOR);
        SetEntityRenderColor(client, 255, 255, 255);

        CPrintToChat(client, "Du bist jetzt wieder sichtbar.");
    }

    return Plugin_Stop;
}

public Action Timer_Unfreeze(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);

    if (IsClientValid(client) && IsPlayerAlive(client))
    {
        SetEntityMoveType(client, MOVETYPE_WALK);
        CPrintToChat(client, "Du kannst nun wieder laufen.");
    }

    return Plugin_Stop;
}

public Action Timer_Drugs(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);

    if (!IsClientInGame(client)) 
        return Plugin_Stop;
    
    float fDrugAngles[20] = {0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0};

    if (!IsPlayerAlive(client))
    {
        float fPosition[3];
        float fAngles[3];
        
        GetClientAbsOrigin(client, fPosition);
        GetClientEyeAngles(client, fAngles);
        
        fAngles[2] = 0.0;
        
        TeleportEntity(client, fPosition, fAngles, NULL_VECTOR);	
        
        Handle hMessage = StartMessageOne("Fade", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
        
        if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf) 
        {
            PbSetInt(hMessage, "duration", 1536);
            PbSetInt(hMessage, "hold_time", 1536);
            PbSetInt(hMessage, "flags", (0x0001 | 0x0010));
            PbSetColor(hMessage, "clr", {0, 0, 0, 0});
        }
        else
        {
            BfWriteShort(hMessage, 1536);
            BfWriteShort(hMessage, 1536);
            BfWriteShort(hMessage, (0x0001 | 0x0010));
            BfWriteByte(hMessage, 0);
            BfWriteByte(hMessage, 0);
            BfWriteByte(hMessage, 0);
            BfWriteByte(hMessage, 0);
        }
        
        EndMessage();	
        
        g_hDrugsTimer[client] = null;
        return Plugin_Stop;
    }
    
    float fPosition[3];
    float fAngles[3];
    int coloring[4];

    coloring[0] = GetRandomInt(0,255);
    coloring[1] = GetRandomInt(0,255);
    coloring[2] = GetRandomInt(0,255);
    coloring[3] = 128;
    
    GetClientAbsOrigin(client, fPosition);
    GetClientEyeAngles(client, fAngles);
    
    fAngles[2] = fDrugAngles[GetRandomInt(0,100) % 20];
    
    TeleportEntity(client, fPosition, fAngles, NULL_VECTOR);

    Handle hMessage = StartMessageOne("Fade", client);

    if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf) 
    {
        PbSetInt(hMessage, "duration", 255);
        PbSetInt(hMessage, "hold_time", 255);
        PbSetInt(hMessage, "flags", (0x0002));
        PbSetColor(hMessage, "clr", coloring);
    }
    else
    {
        BfWriteShort(hMessage, 255);
        BfWriteShort(hMessage, 255);
        BfWriteShort(hMessage, (0x0002));
        BfWriteByte(hMessage, GetRandomInt(0,255));
        BfWriteByte(hMessage, GetRandomInt(0,255));
        BfWriteByte(hMessage, GetRandomInt(0,255));
        BfWriteByte(hMessage, 128);
    }

    EndMessage();

    return Plugin_Handled;
}

public Action Timer_Drunk(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);

    if (!IsClientInGame(client))
    {
        return Plugin_Stop;
    }

    if (g_hDrunkTimer[client] == null)
    {
        return Plugin_Continue;
    }
    
    if (!IsPlayerAlive(client))
    {
        SetRandomAngles(client);
        
        g_hDrugsTimer[client] = null;
        return Plugin_Stop;
    }

    SetRandomAngles(client);

    return Plugin_Continue;
}

public Action Timer_DelayedSlay(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);

    if (!IsClientInGame(client))
    {
        return Plugin_Stop;
    }
    
    if (!IsPlayerAlive(client))
    {
        g_hDelayedSlay[client] = null;
        return Plugin_Stop;
    }

    ForcePlayerSuicide(client);
    CPrintToChat(client, "Die Zeit ist verstrichen und wurdest einfach erschlagen.");

    g_hDelayedSlay[client] = null;
    return Plugin_Stop;
}

void StartJihad(int client)
{
    float fPos[3];
    GetClientEyePosition(client, fPos);

    EmitAmbientSoundAny(JIHAD_SOUND, fPos, SOUND_FROM_PLAYER, .vol=0.8);

    CreateTimer(2.0, Timer_Detonate, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Detonate(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);

    if (client > 0 && IsPlayerAlive(client))
    {
        int iExplosion = CreateEntityByName("env_explosion");
        if (iExplosion != -1)
        {
            SetEntProp(iExplosion, Prop_Data, "m_spawnflags", 16384);
            SetEntProp(iExplosion, Prop_Data, "m_iMagnitude", 666);
            SetEntProp(iExplosion, Prop_Data, "m_iRadiusOverride", 333);
            DispatchKeyValue(iExplosion, "targetname", "jihad");

            DispatchSpawn(iExplosion);
            ActivateEntity(iExplosion);

            float fPosition[3];
            GetClientEyePosition(client, fPosition);

            TeleportEntity(iExplosion, fPosition, NULL_VECTOR, NULL_VECTOR);
            SetEntPropEnt(iExplosion, Prop_Send, "m_hOwnerEntity", client);

            EmitAmbientSoundAny(EXPLOSION_SOUND, fPosition, SOUND_FROM_PLAYER, SNDLEVEL_RAIDSIREN);


            AcceptEntityInput(iExplosion, "Explode");

            AcceptEntityInput(iExplosion, "Kill");
            
            // Slay players
            ForcePlayerSuicide(client);
        }
    }

    return Plugin_Handled;
}

void SetRandomAngles(int client)
{
    float fAngles[3];
    fAngles[0] = GetRandomFloat(-89.0, 89.0);
    fAngles[1] = GetRandomFloat(-179.0, 179.0);
    TeleportEntity(client, .angles=fAngles);
}

public Action Timer_BitchSlap(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	int damage = pack.ReadCell();
	bool sound = view_as<bool>(pack.ReadCell());
	
	if(IsClientValid(client))
	{
		if(g_iBSCount[client] >= 0)
		{
			SlapPlayer(client, damage, sound);
			g_iBSCount[client]--;
			
			if(g_iBSCount[client] == 0)
			{
				ResetBitchSlap(client);
				return Plugin_Stop;
			}
		}
	}
	return Plugin_Continue;
}

void ResetBitchSlap(int client)
{
	g_iBSCount[client] = 0;
	if(g_hBitchSlap[client] != null)
		KillTimer(g_hBitchSlap[client], false);
	g_hBitchSlap[client] = null;
}

public Action Timer_CheckPlayers(Handle timer, DataPack pack)
{
    pack.Reset();
    
    int client = GetClientOfUserId(pack.ReadCell());
    int entity = EntRefToEntIndex(pack.ReadCell());
    
    if (IsClientValid(client) && IsValidEntity(entity))
    {
        float fEOrigin[3], fCOrigin[3], fDistance;
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fEOrigin);
        
        LoopClients(victim)
        {
            if (GetClientTeam(client) == GetClientTeam(victim) && IsPlayerAlive(victim))
            {
                GetClientAbsOrigin(victim, fCOrigin);
                fDistance = GetVectorDistance(fEOrigin, fCOrigin);

                if (fDistance <= 145.0)
                {
                    int iFire = GetEntPropEnt(victim, Prop_Data, "m_hEffectEntity");

                    if (IsValidEdict(iFire))
                    {
                        SetEntPropFloat(iFire, Prop_Data, "m_flLifetime", 0.0);
                    }
                }
            }
        }
        
        DataPack pack2 = new DataPack();
        CreateDataTimer(1.0, Timer_CheckPlayers, pack2, TIMER_FLAG_NO_MAPCHANGE);
        pack2.WriteCell(GetClientUserId(client));
        pack2.WriteCell(EntIndexToEntRef(entity));
    }
    
    return Plugin_Stop;
}

public Action NoclipTimer(Handle timer, any client)
{
    if (IsClientValid(client) && IsPlayerAlive(client))
    {
        if (g_iNoclipCounter[client] > 0)
        {
            CPrintToChat(client, "Noclip endet in: %s%i", SPECIAL, g_iNoclipCounter[client]);
            
            g_iNoclipCounter[client]--;
            
            return Plugin_Continue;
        }
        else
        {
            SetEntityMoveType(client, MOVETYPE_WALK);
            
            if (IsClientStuck(client))
            {
                ForcePlayerSuicide(client);
            }
        }
    }
    
    g_hNoclip[client] = null;
    
    return Plugin_Stop;
}

public Action LowGravityTimer(Handle timer, any client)
{
    if (IsClientValid(client) && IsPlayerAlive(client))
    {
        SetEntityGravity(client, 0.5);
        
        return Plugin_Continue;
    }
    
    g_hLowGravity[client] = null;
    
    return Plugin_Stop;
}

public Action HighGravityTimer(Handle timer, any client)
{
    if (IsClientValid(client) && IsPlayerAlive(client))
    {
        if (!g_bInWater[client])
        {
            SetEntityGravity(client, 1.8);
        }
        
        return Plugin_Continue;
    }
    
    g_hHighGravity[client] = null;
    
    return Plugin_Stop;
}

public Action Timer_RespawnPlayer(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);

    if (IsClientValid(client))
    {
        CS_RespawnPlayer(client);
        g_bRespawn[client] = false;
    }

    return Plugin_Stop;
}

public int Panel_Nothing(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }

    return 0;
}
