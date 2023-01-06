public Action Command_AutoDice(int client, int args)
{
    ShowAutoDiceMenu(client);

    return Plugin_Continue;
}

void ShowAutoDiceMenu(int client)
{
    if (client < 1)
    {
        return;
    }

    char sBuffer[32];

    Panel panel = new Panel();
    panel.SetTitle("Auto Dice Settings");
    panel.DrawText("Möchtest du automatisch Würfeln?");
    panel.DrawText(" ");
    
    FormatEx(sBuffer, sizeof(sBuffer), "[%s] CT-Würfel", (g_bAutoCTDice[client]) ? "X" : " ");
    panel.DrawItem(sBuffer);
    
    FormatEx(sBuffer, sizeof(sBuffer), "[%s] 1. T-Würfel", (g_bAutoT1Dice[client]) ? "X" : " ");
    panel.DrawItem(sBuffer);
    
    FormatEx(sBuffer, sizeof(sBuffer), "[%s] 2. T-Würfel", (g_bAutoT2Dice[client]) ? "X" : " ");
    panel.DrawItem(sBuffer);

    panel.DrawText(" ");
    panel.DrawItem("Schließen");
    panel.Send(client, Panel_AutoDice, 30);

    delete panel;
}

public int Panel_AutoDice(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Select)
    {
        if (param == 1)
        {
            g_bAutoCTDice[client] = !g_bAutoCTDice[client];
            SetDiceSetting(client, g_hAutoCTDice, g_bAutoCTDice[client]);
        }
        else if (param == 2)
        {
            g_bAutoT1Dice[client] = !g_bAutoT1Dice[client];
            SetDiceSetting(client, g_hAutoT1Dice, g_bAutoT1Dice[client]);
        }
        else if (param == 3)
        {
            g_bAutoT2Dice[client] = !g_bAutoT2Dice[client];
            SetDiceSetting(client, g_hAutoT2Dice, g_bAutoT2Dice[client]);
        }
    }

    return 0;
}

void SetDiceSetting(int client, Handle cookie, bool value)
{
    char sBuffer[4];
    IntToString(value, sBuffer, sizeof(sBuffer));
    SetClientCookie(client, cookie, sBuffer);

    ShowAutoDiceMenu(client);
}

public Action Timer_AutoDice(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    int team = GetClientTeam(client);

    if (g_bReady && client && IsPlayerAlive(client) && (team == CS_TEAM_T || team == CS_TEAM_CT) && !g_bBusy[client] && g_hDiceTimer[client] == null)
    {
        if (team == CS_TEAM_CT && g_iCount[client] == 0 && g_bAutoCTDice[client])
        {
            ClientCommand(client, "sm_w");
        }
        else if (team == CS_TEAM_T && g_iCount[client] == 0 && g_bAutoT1Dice[client])
        {
            ClientCommand(client, "sm_w");
        }
        else if (team == CS_TEAM_T && g_iCount[client] == 1 && STAMM_HaveClientFeature(client) && g_bAutoT2Dice[client])
        {
            ClientCommand(client, "sm_w");
        }
    }

    return Plugin_Stop;
}
