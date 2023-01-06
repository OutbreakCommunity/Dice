int GiveDiceOption(int client, DiceOption Option, int team, int dice, Panel panel, float chance)
{
    char sDice[24], sText[MAX_MESSAGE_LENGTH], sText1[MAX_MESSAGE_LENGTH], sText2[MAX_MESSAGE_LENGTH];
    int type = -1;

    if (team == CS_TEAM_CT)
    {
        FormatEx(sDice, sizeof(sDice), "CT-Würfel");
    }
    else
    {
        FormatEx(sDice, sizeof(sDice), "%d. T-Würfel", dice);
    }
    
    
    if (StrEqual(Option.Name, "nothing", false))
    {
        Format(sText, sizeof(sText), "Du hast beim %s %snichts%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 1;
    }
    else if (StrEqual(Option.Name, "shield", false))
    {
        bool bSkip = false;

        int iWeapon = GetPlayerWeaponSlot(client, 11);
        if (iWeapon != -1)
        {
            if (IsValidEdict(iWeapon) && IsValidEntity(iWeapon))
            {
                char sClass[128];
                GetEntityClassname(iWeapon, sClass, sizeof(sClass));

                if (StrEqual(sClass, "weapon_shield", false))
                {
                    Format(sText, sizeof(sText), "Du hast beim %s %snichts%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);

                    type = 1;

                    bSkip = true;
                }
            }
        }

        if (!bSkip)
        {
            GivePlayerItem(client, "weapon_shield");
            
            Format(sText, sizeof(sText), "Du hast durch den %s %sein Schield%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
            type = 2;
        }
        else
        {
            Format(sText, sizeof(sText), "Du hast durch den %s %sein Schield%s gewürfelt...", sDice, SPECIAL, TEXT);
            Format(sText1, sizeof(sText1), "Leider konnten wir dir dein Schild geben.");
            type = 1;
        }
    }
    else if (StrEqual(Option.Name, "reroll", false))
    {
        g_iCount[client] = 0;

        Format(sText, sizeof(sText), "Du hast beim %s %sErneut Würfeln%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 2;
    }
    else if (StrEqual(Option.Name, "helm", false))
    {
        SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);

        Format(sText, sizeof(sText), "Du hast beim %s %sein Helm%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 2;
    }
    else if (StrEqual(Option.Name, "respawn", false))
    {
        g_bRespawn[client] = true;

        Format(sText, sizeof(sText), "Du hast beim %s %sRespawn (50% Chance)%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 2;
    }
    else if (StrEqual(Option.Name, "speed", false))
    {
        int iSpeed = GetRandomInt(1, 3);
        float fSpeed = iSpeed / 10.0;

        SetClientSpeed(client, (GetClientSpeed(client) + fSpeed));

        Format(sText, sizeof(sText), "Du hast beim %s %sSpeed (%.0f%)%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, (fSpeed * 100), TEXT, chance);
        type = 2;
    }
    else if (StrEqual(Option.Name, "noHeadshot", false))
    {
        g_bHeadshot[client] = true;

        Format(sText, sizeof(sText), "Du hast beim %s %skein Headshot Schaden (bekommen)%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 2;
    }
    else if (StrEqual(Option.Name, "lessDamage", false))
    {
        float fDamage = GetRandomFloat(5.0, 15.0);
        g_fDamage[client] = 1.0 + (fDamage / 100.0);

        g_bLessDamage[client] = true;

        Format(sText, sizeof(sText), "Du hast beim %s %sweniger Schaden (%.2f weniger bekommen)%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, g_fDamage[client], TEXT, chance);
        type = 2;
    }
    else if (StrEqual(Option.Name, "healthshot", false))
    {
        GivePlayerItem(client, "weapon_healthshot");

        Format(sText, sizeof(sText), "Du hast beim %s %seine Heilspritze%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 2;
    }
    else if (StrEqual(Option.Name, "moreDamage", false))
    {
        float fDamage = GetRandomFloat(10.0, 30.0);
        g_fDamage[client] = 1.0 + (fDamage / 100.0);

        g_bMoreDamage[client] = true;

        Format(sText, sizeof(sText), "Du hast beim %s %smehr Schaden (%.2f mehr geben)%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, g_fDamage[client], TEXT, chance);
        type = 2;
    }
    else if (StrEqual(Option.Name, "tagrenade", false))
    {
        GivePlayerItem(client, "weapon_tagrenade");

        Format(sText, sizeof(sText), "Du hast beim %s %seine TA-Grenade%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 2;
    }
    else if (StrEqual(Option.Name, "+50hp", false))
    {
        // +50 hp
        SetHealth(client, 50, true);
        
        Format(sText, sizeof(sText), "Du hast beim %s %s+50 HP%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 2;
    }
    else if (StrEqual(Option.Name, "lowGravity", false))
    {
        // low grav
        SetEntityGravity(client, 0.5);
        g_hLowGravity[client] = CreateTimer(1.0, LowGravityTimer, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
        
        Format(sText, sizeof(sText), "Du hast beim %s %slow Gravity%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 2;
    }
    else if (StrEqual(Option.Name, "taser", false))
    {
        // taser
        RequestFrame(Frame_GiveTaser, GetClientUserId(client));
        
        Format(sText, sizeof(sText), "Du hast beim %s %seinen Taser%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 2;
    }
    else if (StrEqual(Option.Name, "drugs", false))
    {
        // drugs
        g_hDrugsTimer[client] = CreateTimer(1.0, Timer_Drugs, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
        
        Format(sText, sizeof(sText), "Du hast beim %s %sDrogen%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 0;
    }
    else if (StrEqual(Option.Name, "froggyjump", false))
    {
        // froggy
        g_bFroggyjump[client] = true;
        
        Format(sText, sizeof(sText), "Du hast beim %s %sFroggyjump%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 2;
    }
    else if (StrEqual(Option.Name, "-45hp", false))
    {
        // -45 hp
        SetHealth(client, 45, false);
        
        Format(sText, sizeof(sText), "Du hast beim %s %s-45 HP%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 0;
    }
    else if (StrEqual(Option.Name, "futuristicGrenade", false))
    {
        // futuristic grenade
        GivePlayerItem(client, "weapon_decoy");

        DecoyMode dmMode = view_as<DecoyMode>(GetRandomInt(view_as<int>(DecoyMode_Normal), view_as<int>(DecoyMode_ForceImplosion)));
        char sPanelOption[32];

        if (dmMode == DecoyMode_Normal)
        {
            FormatEx(sPanelOption, sizeof(sPanelOption), "Normal");
            Format(Option.Name, sizeof(DiceOption::Name), "normalDecoy");
        }
        else if (dmMode == DecoyMode_Blackhole)
        {
            FormatEx(sPanelOption, sizeof(sPanelOption), "Blackhole");
            Format(Option.Name, sizeof(DiceOption::Name), "blackholeDecoy");
        }
        else if (dmMode == DecoyMode_Forcefield)
        {
            dmMode = DecoyMode_Normal;

            FormatEx(sPanelOption, sizeof(sPanelOption), "Normal");
            Format(Option.Name, sizeof(DiceOption::Name), "normalDecoy");
        }
        else if (dmMode == DecoyMode_ForceExplosion)
        {
            FormatEx(sPanelOption, sizeof(sPanelOption), "Explosion");
            Format(Option.Name, sizeof(DiceOption::Name), "explosionDecoy");
        }
        else if (dmMode == DecoyMode_ForceImplosion)
        {
            FormatEx(sPanelOption, sizeof(sPanelOption), "Implosion");
            Format(Option.Name, sizeof(DiceOption::Name), "implosionDecoy");
        }

        g_dmFuturistic[client] = dmMode;
        FGrenades_SwitchMode(client, dmMode);

        Format(sText, sizeof(sText), "Du hast beim %s %s%s%s Decoy gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, sPanelOption, TEXT, chance);
        type = 2;
    }
    else if (StrEqual(Option.Name, "slow", false))
    {
        // slow
        int iSpeed = GetRandomInt(2, 4);
        float fSpeed = iSpeed / 10.0;

        SetClientSpeed(client, (GetClientSpeed(client) - fSpeed));
        
        Format(sText, sizeof(sText), "Du hast beim %s %sSlow (+%.0f%%)%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, (fSpeed * 100), TEXT, chance);
        type = 0;
    }
    else if (StrEqual(Option.Name, "flashbang", false))
    {
        // 1 flash
        GivePlayerItem(client, "weapon_flashbang");
        
        Format(sText, sizeof(sText), "Du hast beim %s %s1 Flash%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 2;
    }
    else if (StrEqual(Option.Name, "freeze", false))
    {
        // freeze
        SetEntityMoveType(client, MOVETYPE_NONE);
        CreateTimer(10.0, Timer_Unfreeze, GetClientUserId(client));
        
        Format(sText, sizeof(sText), "Du hast beim %s %s10 Sekunden Freeze%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 0;
    }
    else if (StrEqual(Option.Name, "smokegrenade", false))
    {
        // smoke
        GivePlayerItem(client, "weapon_smokegrenade");
        
        Format(sText, sizeof(sText), "Du hast beim %s %seine Smoke%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 2;
    }
    else if (StrEqual(Option.Name, "tSwap", false))
    {
        // t swap
        int iOpponent = GetRandomPlayer(client, CS_TEAM_T);

        if (iOpponent < 1)
        {
            Format(sText, sizeof(sText), "Du hast beim %s %sT Spawn %sgewürfelt...", sDice, SPECIAL, TEXT);
            Format(sText1, sizeof(sText1), "Kein Spieler für T-Swap gefunden, Sorry.");
            type = 0;
        }
        else
        {
            float fClientPosition[3], fOpponentPosition[3];
            GetClientAbsOrigin(client, fClientPosition);
            GetClientAbsOrigin(iOpponent, fOpponentPosition);

            TeleportEntity(client, fOpponentPosition);
            TeleportEntity(iOpponent, fClientPosition);

            CPrintToChat(iOpponent, "%s%N %shat mit dir die Position getauscht.", SPECIAL, client, TEXT);
            
            Format(sText, sizeof(sText), "Du hast beim %s %sT Spawn %smit %s%N%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, SPECIAL, iOpponent, TEXT, chance);
            type = 1;
        }
    }
    else if (StrEqual(Option.Name, "longjump", false))
    {
        // longjump
        g_bLongjump[client] = true;
        
        Format(sText, sizeof(sText), "Du hast beim %s %sLongjump%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 2;
    }
    else if (StrEqual(Option.Name, "zombie", false))
    {
        // zombie
        g_bZombie[client] = true;
        
        Format(sText, sizeof(sText), "Du hast beim %s %sZombie Mode%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 0;
    }
    else if (StrEqual(Option.Name, "bhop", false))
    {
        // bhop
        g_bBhop[client] = true;
        
        Format(sText, sizeof(sText), "Du hast beim %s %sein Bhop Script%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 2;
    }
    else if (StrEqual(Option.Name, "mirrorMovement", false))
    {
        // mirror movement
        g_bMirrorMovement[client] = true;
        
        Format(sText, sizeof(sText), "Du hast beim %s %sMirrored Movement%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 0;
    }
    else if (StrEqual(Option.Name, "kevlarHelm", false))
    {
        // kevlar + helm
        GivePlayerItem(client, "item_assaultsuit");
        SetEntProp(client, Prop_Send, "m_ArmorValue", 100, 1);
        
        Format(sText, sizeof(sText), "Du hast beim %s %seine Kevlar mit Helm%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 2;
    }
    else if (StrEqual(Option.Name, "invisible", false))
    {
        // invisible
        float fTime = GetRandomInt(3, 5) * 1.0;

        CreateTimer(fTime, Timer_ResetInvisible, GetClientUserId(client));
        SetEntityRenderMode(client, RENDER_NONE);
        
        Format(sText, sizeof(sText), "Du hast beim %s %s%.0f Sekunden Unsichtbar%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, fTime, TEXT, chance);
        type = 2;
    }
    else if (StrEqual(Option.Name, "noclip", false))
    {
        // noclip
        SetEntityMoveType(client, MOVETYPE_NOCLIP);
        g_hNoclip[client] = CreateTimer(1.0, NoclipTimer, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
        
        Format(sText, sizeof(sText), "Du hast beim %s %sNoclip%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 2;
    }
    else if (StrEqual(Option.Name, "weapon", false))
    {
        // cz/revolver
        bool bCZ75 = view_as<bool>(GetRandomInt(0, 1));
        int iWeapon = GivePlayerItem(client, bCZ75 ? "weapon_cz75a" : "weapon_revolver");
        SetEntData(iWeapon, g_iClip1, (bCZ75) ? 12 : 8);
        SetEntProp(iWeapon, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
        
        Format(sText, sizeof(sText), "Du hast beim %s %seine %s%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, bCZ75 ? "CZ" : "Revolver", TEXT, chance);
        Format(Option.Name, sizeof(DiceOption::Name), bCZ75 ? "cz" : "revolver");
        type = 2;
    }
    else if (StrEqual(Option.Name, "-50hp", false))
    {
        // -50 hp
        SetHealth(client, 50, false);
        
        Format(sText, sizeof(sText), "Du hast beim %s %s-50 HP%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 0;
    }
    else if (StrEqual(Option.Name, "burn", false))
    {
        // anbrennen
        IgniteEntity(client, 14.0);
        
        Format(sText, sizeof(sText), "Du hast beim %s %sanbrennen%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 0;
    }
    else if (StrEqual(Option.Name, "assassine", false))
    {
        // Assassine
        g_bAssassine[client] = true;
        
        Format(sText, sizeof(sText), "Du hast beim %s %sAssassine%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        Format(sText1, sizeof(sText1), "Man kann deine Kill's nicht mehr sehen");
        Format(sText2, sizeof(sText2), "Kleiner Tipp: Ergib dich als Assassine nicht!");
        type = 2;
    }
    else if (StrEqual(Option.Name, "loseall", false))
    {
        // Strip all
        StripAllWeapons(client);
        g_bLose[client] = true;
        
        Format(sText, sizeof(sText), "Du hast beim %s %salles verloren%s.", sDice, SPECIAL, TEXT);
        type = 0;
    }
    else if (StrEqual(Option.Name, "slay", false))
    {
        // selbstmordattentäter
        ForcePlayerSuicide(client);

        Format(sText, sizeof(sText), "Du hast beim %s %sSlay%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 0;
    }
    else if (StrEqual(Option.Name, "highGravity", false))
    {
        // High grav
        SetEntityGravity(client, 1.8);
        g_hHighGravity[client] = CreateTimer(1.0, HighGravityTimer, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
        
        Format(sText, sizeof(sText), "Du hast beim %s %shigh Gravity%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 0;
    }
    else if (StrEqual(Option.Name, "tollpatsch", false))
    {
        // Tollpatsch
        g_bTollpatsch[client] = true;
        
        Format(sText, sizeof(sText), "Du hast beim %s %sTollpatsch%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 0;
    }
    else if (StrEqual(Option.Name, "refuse", false))
    {
        // 2nd refuse
        Jail_AddClientRefuse(client);
        
        Format(sText, sizeof(sText), "Du hast beim %s %s2. Verweigern%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 2;
    }
    else if (StrEqual(Option.Name, "hegrenade", false))
    {
        // Granate
        GivePlayerItem(client, "weapon_hegrenade");
        
        Format(sText, sizeof(sText), "Du hast beim %s %seine Granate%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 2;
    }
    else if (StrEqual(Option.Name, "decoyTeleport", false))
    {
        GivePlayerItem(client, "weapon_decoy");
        g_bDecoy[client] = true;
        
        Format(sText, sizeof(sText), "Du hast beim %s %sein Decoy Teleport%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 2;
    }
    else if (StrEqual(Option.Name, "jihad", false))
    {
        GivePlayerItem(client, "weapon_c4");
        g_bJihad[client] = true;
        
        Format(sText, sizeof(sText), "Du hast beim %s %seine Jihad-Bombe%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        Format(sText1, sizeof(sText1), "Nimm die Bombe in der Hand und drücke E zum aktivieren.");
        type = 2;
    }
    else if (StrEqual(Option.Name, "drunk", false))
    {
        // drunk
        g_hDrunkTimer[client] = CreateTimer(5.0, Timer_Drunk, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
        SetRandomAngles(client);
        
        Format(sText, sizeof(sText), "Du hast beim %s %sBetrunken%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 0;
    }
    else if (StrEqual(Option.Name, "nofalldamage", false))
    {
        // nofalldamage
        g_bNoFallDamage[client] = true;
        
        Format(sText, sizeof(sText), "Du hast beim %s %sNo Fall Damage%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 2;
    }
    else if (StrEqual(Option.Name, "gohan", false))
    {
        // gohan
        SetGohanMode(client, true);
        
        Format(sText, sizeof(sText), "Du hast beim %s %sSon Gohan%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        Format(sText1, sizeof(sText1), "Lade dein Kame Hame He mit der Reload Taste auf.");
        type = 2;
    }
    else if (StrEqual(Option.Name, "fists", false))
    {
        // fists
        StripAllWeapons(client);
        int iWeapon = GivePlayerItem(client, "weapon_fists");
        EquipPlayerWeapon(client, iWeapon);
        
        Format(sText, sizeof(sText), "Du hast beim %s %sFäuste%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        Format(sText1, sizeof(sText1), "Hast aber alles andere verloren...");
        type = 0;
    }
    else if (StrEqual(Option.Name, "hammer", false))
    {
        // hammer
        StripAllWeapons(client);
        int iWeapon = GivePlayerItem(client, "weapon_hammer");
        EquipPlayerWeapon(client, iWeapon);
        
        Format(sText, sizeof(sText), "Du hast beim %s %sein Hammer%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        Format(sText1, sizeof(sText1), "Hast aber alles andere verloren...");
        type = 0;
    }
    else if (StrEqual(Option.Name, "axe", false))
    {
        // axe
        StripAllWeapons(client);
        int iWeapon = GivePlayerItem(client, "weapon_axe");
        EquipPlayerWeapon(client, iWeapon);
        
        Format(sText, sizeof(sText), "Du hast beim %s %seine Axt%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        Format(sText1, sizeof(sText1), "Hast aber alles andere verloren...");
        type = 0;
    }
    else if (StrEqual(Option.Name, "spanner", false))
    {
        // spanner
        StripAllWeapons(client);
        int iWeapon = GivePlayerItem(client, "weapon_spanner");
        EquipPlayerWeapon(client, iWeapon);
        
        Format(sText, sizeof(sText), "Du hast beim %s %sein Schraubenschlüssel%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        Format(sText1, sizeof(sText1), "Hast aber alles andere verloren...");
        type = 0;
    }
    else if (StrEqual(Option.Name, "rentner", false))
    {
        // rentner
        g_bRentner[client] = true;
        int iSpeed = GetRandomInt(2, 4);
        float fSpeed = iSpeed / 10.0;

        SetClientSpeed(client, (GetClientSpeed(client) - fSpeed));
        
        Format(sText, sizeof(sText), "Du bist beim %s wohl %seingeschlafen und gealtert%s? (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 0;
    }
    else if (StrEqual(Option.Name, "delayedSlay", false))
    {
        // delayedSlay
        float fRoundTimeLeft = float(GameRules_GetProp("m_iRoundTime"));
        float fTime = GetRandomFloat(5.0, fRoundTimeLeft);
        g_hDelayedSlay[client] = CreateTimer(fTime, Timer_DelayedSlay, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
        
        Format(sText, sizeof(sText), "Du hast beim %s %sDie Zeit%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 0;
    }
    else if (StrEqual(Option.Name, "lover", false))
    {
        // lover
        g_iLover[client] = GetRandomPlayer(client, GetClientTeam(client));

        if (g_iLover[client] == -1)
        {
            Format(sText, sizeof(sText), "Du hast beim %s %snichts%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        }
        else
        {
            Format(sText, sizeof(sText), "Du hast beim %s %sLover%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
            Format(sText1, sizeof(sText1), "Kümmere dich gut um %s%N%s, sonst stirbt du auch.", SPECIAL, g_iLover[client], TEXT);
        }

        type = 1;
    }
    else if (StrEqual(Option.Name, "noDMGawp", false))
    {
        // no damage awp
        g_bAWP[client] = true;

        int iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);

        if (iWeapon != -1)
        {
            SafeRemoveWeapon(client, iWeapon);
        }

        iWeapon = GivePlayerItem(client, "weapon_awp");
        SetEntData(iWeapon, g_iClip1, 1);
        SetEntProp(iWeapon, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
        
        Format(sText, sizeof(sText), "Du hast beim %s %seine AWP%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        type = 0;
    }
    else if (StrEqual(Option.Name, "bitchslap", false))
    {
        // BitchSlap
        g_iBSCount[client] = GetRandomInt(1, 30);
        float fInterval = GetRandomFloat(0.1, 10.0);
        int iDamage = GetRandomInt(0, 5);
        bool bSound = view_as<bool>(GetRandomInt(0, 1));

        SlapPlayer(client, iDamage, bSound);
        g_iBSCount[client]--;
        
        DataPack pack = new DataPack();
        g_hBitchSlap[client] = CreateDataTimer(fInterval, Timer_BitchSlap, pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        WritePackCell(pack, client);
        WritePackCell(pack, iDamage);
        WritePackCell(pack, bSound);
        
        Format(sText, sizeof(sText), "Du hast beim %s %sBitch Slap%s gewürfelt. (Chance: %.2f%%)", sDice, SPECIAL, TEXT, chance);
        Format(sText1, sizeof(sText1), "Anzahl: %d, Interval: %.2f, Damage: %d, Sound: %s", g_iBSCount[client], fInterval, iDamage, (bSound) ? "Ja" : "Nein");

        type = 0;
    }

    if (strlen(sText) < 1)
    {
        LogStackTrace("Option is empty. Player: %N, Team: %d, Dice: %d, Option: %s(?)", client, team, dice, Option.Name);
        CPrintToChat(client, "Herzlichen Glückwunsch, dein Würfel ist kaputt.");
        return 0;
    }

    if (team == CS_TEAM_CT)
    {
        Format(Option.Name, sizeof(DiceOption::Name), "(ct) %s", Option.Name);
    }
    
    if (!Option.Debug)
    {
        AddDiceToMySQL(client, dice, Option.Name, type);
    }

    char sChatMessage[MAX_MESSAGE_LENGTH];
    strcopy(sChatMessage, sizeof(sChatMessage), sText);

    char sChatMessage1[MAX_MESSAGE_LENGTH];
    strcopy(sChatMessage1, sizeof(sChatMessage1), sText1);

    char sChatMessage2[MAX_MESSAGE_LENGTH];
    strcopy(sChatMessage2, sizeof(sChatMessage2), sText2);


    int iPosition = StrContains(sChatMessage, " (Chance", false);

    if (iPosition > 3)
    {
        sChatMessage[iPosition] = '\0';
    }

    panel.SetTitle("Dice");

    CRemoveTags(sText, sizeof(sText));
    panel.DrawText(sText);
    CPrintToChat(client, sChatMessage);

    if (strlen(sText1) > 2)
    {
        CPrintToChat(client, sChatMessage1);
        CRemoveTags(sText1, sizeof(sText1));
        panel.DrawText(sText1);
    }

    if (strlen(sText2) > 2)
    {
        CPrintToChat(client, sChatMessage2);
        CRemoveTags(sText2, sizeof(sText2));
        panel.DrawText(sText2);
    }

    return type;
}