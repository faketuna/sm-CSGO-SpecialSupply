#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "0.0.1"

enum {
    WEAPON_BREACH_CHARGE = 0,
    WEAPON_BUMPMINE,
    WEAPON_SHIELD
}

ConVar g_cvPluginEnabled;
bool g_bPluginEnabled;

bool g_bPlayerHasBoughtSpecificItem[MAXPLAYERS+1][3];

ConVar g_cvOnlyInBuyzone;
bool g_bOnlyInBuyZone;

ConVar g_cvPriceShield;
ConVar g_cvPriceBreachCharge;
ConVar g_cvPriceBumpmine;
int g_iSSPWeaponPrices[3];

ConVar g_cvClipBreachCharge;
ConVar g_cvClipBumpmine;
int g_iSSPWeaponClip[2];

public Plugin myinfo =
{
    name = "[CS:GO] Special supply",
    author = "faketuna",
    description = "Make some items buyable",
    version = PLUGIN_VERSION,
    url = "http://www.theville.org"
}

public void OnPluginStart() {
    g_cvPluginEnabled           = CreateConVar("sm_special_supply_enabled", "0", "Toggles special supply", FCVAR_NONE, true, 0.0, true, 1.0);
    g_cvOnlyInBuyzone           = CreateConVar("sm_special_supply_only_buyzone", "1", "Toggles buyable timing", FCVAR_NONE, true, 0.0, true, 1.0);
    g_cvPriceBreachCharge       = CreateConVar("sm_special_supply_price_bcharge", "3000", "Price of breach charge", FCVAR_NONE, true, 0.0, true, 10000.0);
    g_cvPriceBumpmine           = CreateConVar("sm_special_supply_price_bumpmine", "3000", "Price of bumpmine", FCVAR_NONE, true, 0.0, true, 10000.0);
    g_cvPriceShield             = CreateConVar("sm_special_supply_price_shield", "3000", "Price of shield", FCVAR_NONE, true, 0.0, true, 10000.0);

    g_cvClipBreachCharge        = CreateConVar("sm_special_supply_clip_bcharge", "3", "Clip of breach charge", FCVAR_NONE, true, 0.0, true, 100.0);
    g_cvClipBumpmine            = CreateConVar("sm_special_supply_clip_bumpmine", "3", "Clip of bumpmine", FCVAR_NONE, true, 0.0, true, 100.0);

    RegConsoleCmd("sm_supply", CommandSpecialSupply, "Special supply buy menu");
    RegConsoleCmd("sm_bumpmine", CommandBuyBumpMine, "Buy Bump Mine");
    RegConsoleCmd("sm_breach", CommandBuyBreachCharge, "Buy Breach Charge");
    RegConsoleCmd("sm_shield", CommandBuyShield, "Buy Shield");

    HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);

    g_cvPluginEnabled.AddChangeHook(OnCvarsChanged);
    g_cvOnlyInBuyzone.AddChangeHook(OnCvarsChanged);
    g_cvPriceBreachCharge.AddChangeHook(OnCvarsChanged);
    g_cvPriceBumpmine.AddChangeHook(OnCvarsChanged);
    g_cvPriceShield.AddChangeHook(OnCvarsChanged);
    g_cvClipBreachCharge.AddChangeHook(OnCvarsChanged);
    g_cvClipBumpmine.AddChangeHook(OnCvarsChanged);


    LoadTranslations("specialSupply.phrases");
}

public void OnConfigsExecuted() {
    SyncConVarValues();
}

public void SyncConVarValues() {
    g_iSSPWeaponPrices[WEAPON_BREACH_CHARGE]    = g_cvPriceBreachCharge.IntValue;
    g_iSSPWeaponPrices[WEAPON_BUMPMINE]         = g_cvPriceBumpmine.IntValue;
    g_iSSPWeaponPrices[WEAPON_SHIELD]           = g_cvPriceShield.IntValue;
    g_iSSPWeaponClip[WEAPON_BREACH_CHARGE]      = g_cvClipBreachCharge.IntValue;
    g_iSSPWeaponClip[WEAPON_BUMPMINE]           = g_cvClipBumpmine.IntValue;
    g_bPluginEnabled                            = g_cvPluginEnabled.BoolValue;
    g_bOnlyInBuyZone                            = g_cvOnlyInBuyzone.BoolValue;
}

public void OnCvarsChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
    SyncConVarValues();
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
    for(int i = 1; i <= MaxClients; i++) {
        g_bPlayerHasBoughtSpecificItem[i][WEAPON_BREACH_CHARGE] = false;
        g_bPlayerHasBoughtSpecificItem[i][WEAPON_BUMPMINE] = false;
        g_bPlayerHasBoughtSpecificItem[i][WEAPON_SHIELD] = false;
    }
    return Plugin_Continue;
}

public Action CommandSpecialSupply(int client, int args) {
    if(!g_bPluginEnabled) {
        CPrintToChat(client, "%t%t", "ssp prefix", "ssp disabled");
        return Plugin_Handled;
    }
    if(g_bOnlyInBuyZone && !IsClientInBuyZone(client)) {
        CPrintToChat(client, "%t%t", "ssp prefix", "ssp only buy zone");
        return Plugin_Handled;
    }

    DisplayBuyMenu(client);
    return Plugin_Handled;
}


public Action CommandBuyBreachCharge(int client, int args) {
    SetGlobalTransTarget(client);
    char weaponName[32];
    Format(weaponName, sizeof(weaponName), "%t", "ssp buy menu weapon breachcharge");

    if(g_bPlayerHasBoughtSpecificItem[client][WEAPON_BREACH_CHARGE]) {
        CPrintToChat(client, "%t%t", "ssp prefix", "ssp already purchased", weaponName);
        return Plugin_Handled;
    }
    if(g_bOnlyInBuyZone && !IsClientInBuyZone(client)) {
        CPrintToChat(client, "%t%t", "ssp prefix", "ssp only buy zone");
        return Plugin_Handled;
    }

    if(GetClientMoney(client) < g_iSSPWeaponPrices[WEAPON_BREACH_CHARGE]) {
        char message[128];
        Format(message, sizeof(message), "%t", "ssp insufficient money", g_iSSPWeaponPrices[WEAPON_BREACH_CHARGE]);
        CPrintToChat(client, "%t%s", "ssp prefix", message);
        return Plugin_Handled;
    }

    GiveWeapon(client, "weapon_breachcharge", g_iSSPWeaponClip[WEAPON_BREACH_CHARGE]);
    SetClientMoney(client, GetClientMoney(client) - g_iSSPWeaponPrices[WEAPON_BREACH_CHARGE]);
    CPrintToChat(client, "%t%t", "ssp prefix", "ssp purchase", weaponName);
    g_bPlayerHasBoughtSpecificItem[client][WEAPON_BREACH_CHARGE] = true;
    return Plugin_Handled;
}

public Action CommandBuyBumpMine(int client, int args) {
    SetGlobalTransTarget(client);
    char weaponName[32];
    Format(weaponName, sizeof(weaponName), "%t", "ssp buy menu weapon bumpmine");

    if(g_bPlayerHasBoughtSpecificItem[client][WEAPON_BUMPMINE]) {
        CPrintToChat(client, "%t%t", "ssp prefix", "ssp already purchased", weaponName);
        return Plugin_Handled;
    }
    if(g_bOnlyInBuyZone && !IsClientInBuyZone(client)) {
        CPrintToChat(client, "%t%t", "ssp prefix", "ssp only buy zone");
        return Plugin_Handled;
    }

    if(GetClientMoney(client) < g_iSSPWeaponPrices[WEAPON_BUMPMINE]) {
        char message[128];
        Format(message, sizeof(message), "%t", "ssp insufficient money", g_iSSPWeaponPrices[WEAPON_BUMPMINE]);
        CPrintToChat(client, "%t%s", "ssp prefix", message);
        return Plugin_Handled;
    }

    GiveWeapon(client, "weapon_bumpmine", g_iSSPWeaponClip[WEAPON_BUMPMINE]);
    SetClientMoney(client, GetClientMoney(client) - g_iSSPWeaponPrices[WEAPON_BUMPMINE]);
    CPrintToChat(client, "%t%t", "ssp prefix", "ssp purchase", weaponName);
    g_bPlayerHasBoughtSpecificItem[client][WEAPON_BUMPMINE] = true;
    return Plugin_Handled;
}

public Action CommandBuyShield(int client, int args) {
    SetGlobalTransTarget(client);
    char weaponName[32];
    Format(weaponName, sizeof(weaponName), "%t", "ssp buy menu weapon shield");

    if(g_bPlayerHasBoughtSpecificItem[client][WEAPON_SHIELD]) {
        CPrintToChat(client, "%t%t", "ssp prefix", "ssp already purchased", weaponName);
        return Plugin_Handled;
    }
    if(g_bOnlyInBuyZone && !IsClientInBuyZone(client)) {
        CPrintToChat(client, "%t%t", "ssp prefix", "ssp only buy zone");
        return Plugin_Handled;
    }

    if(GetClientMoney(client) < g_iSSPWeaponPrices[WEAPON_SHIELD]) {
        char message[128];
        Format(message, sizeof(message), "%t", "ssp insufficient money", g_iSSPWeaponPrices[WEAPON_SHIELD]);
        CPrintToChat(client, "%t%s", "ssp prefix", message);
        return Plugin_Handled;
    }
    
    GiveWeapon(client, "weapon_shield");
    SetClientMoney(client, GetClientMoney(client) - g_iSSPWeaponPrices[WEAPON_SHIELD]);
    CPrintToChat(client, "%t%t", "ssp prefix", "ssp purchase", weaponName);
    g_bPlayerHasBoughtSpecificItem[client][WEAPON_SHIELD] = true;
    return Plugin_Handled;
}

void DisplayBuyMenu(int client) {
    SetGlobalTransTarget(client);
    Menu prefmenu = CreateMenu(BuyMenuHandler, MenuAction_Display|MenuAction_DisplayItem|MenuAction_DrawItem);

    char menuTitle[64];
    Format(menuTitle, sizeof(menuTitle), "%t", "ssp buy menu", client);
    prefmenu.SetTitle(menuTitle);

    char display[128];
    // BREACH CHARGE
    if(g_bPlayerHasBoughtSpecificItem[client][WEAPON_BREACH_CHARGE]) {
        Format(display, sizeof(display), "%t: %t", "ssp buy menu weapon breachcharge", "ssp buy menu already purchased");
        prefmenu.AddItem("_", display, ITEMDRAW_DISABLED);
    }
    else if (GetClientMoney(client) < g_iSSPWeaponPrices[WEAPON_BREACH_CHARGE]) {
        Format(display, sizeof(display), "%t: $%d | !breach", "ssp buy menu weapon breachcharge", g_iSSPWeaponPrices[WEAPON_BREACH_CHARGE]);
        prefmenu.AddItem("_", display, ITEMDRAW_DISABLED);
    }
    else {
        Format(display, sizeof(display), "%t: $%d | !breach", "ssp buy menu weapon breachcharge", g_iSSPWeaponPrices[WEAPON_BREACH_CHARGE]);
        prefmenu.AddItem("breachcharge", display, ITEMDRAW_DEFAULT);
    }
    
    // BUMP MINE
    if(g_bPlayerHasBoughtSpecificItem[client][WEAPON_BUMPMINE]) {
        Format(display, sizeof(display), "%t: %t", "ssp buy menu weapon bumpmine", "ssp buy menu already purchased");
        prefmenu.AddItem("_", display, ITEMDRAW_DISABLED);
    }
    else if (GetClientMoney(client) < g_iSSPWeaponPrices[WEAPON_BUMPMINE]) {
        Format(display, sizeof(display), "%t: $%d | !bumpmine", "ssp buy menu weapon bumpmine", g_iSSPWeaponPrices[WEAPON_BUMPMINE]);
        prefmenu.AddItem("_", display, ITEMDRAW_DISABLED);
    }
    else {
        Format(display, sizeof(display), "%t: $%d | !bumpmine", "ssp buy menu weapon bumpmine", g_iSSPWeaponPrices[WEAPON_BUMPMINE]);
        prefmenu.AddItem("bumpmine", display, ITEMDRAW_DEFAULT);
    }
    
    // SHIELD
    if(g_bPlayerHasBoughtSpecificItem[client][WEAPON_SHIELD]) {
        Format(display, sizeof(display), "%t: %t", "ssp buy menu weapon shield", "ssp buy menu already purchased");
        prefmenu.AddItem("", display, ITEMDRAW_DISABLED);
    }
    else if (GetClientMoney(client) < g_iSSPWeaponPrices[WEAPON_SHIELD]) {
        Format(display, sizeof(display), "%t: $%d | !shield", "ssp buy menu weapon shield", g_iSSPWeaponPrices[WEAPON_SHIELD]);
        prefmenu.AddItem("", display, ITEMDRAW_DISABLED);
    }
    else {
        Format(display, sizeof(display), "%t: $%d | !shield", "ssp buy menu weapon shield", g_iSSPWeaponPrices[WEAPON_SHIELD]);
        prefmenu.AddItem("shield", display, ITEMDRAW_DEFAULT);
    }

    prefmenu.Display(client, 6);
}

public int BuyMenuHandler(Menu prefmenu, MenuAction actions, int client, int item)
{
    if (actions == MenuAction_Select) {
        char preference[16];

        GetMenuItem(prefmenu, item, preference, sizeof(preference));

        if(StrEqual(preference, "breachcharge")) {
            FakeClientCommand(client, "sm_breach");
        }
        else if(StrEqual(preference, "bumpmine")) {
            FakeClientCommand(client, "sm_bumpmine");
        }
        else if(StrEqual(preference, "shield")) {
            FakeClientCommand(client, "sm_shield");
        }
        DisplayBuyMenu(client);
    }
    else if(actions == MenuAction_DrawItem) {
        int style;
        char preference[16];

        GetMenuItem(prefmenu, item, preference, sizeof(preference), style);
        return style;
    }
    else if (actions == MenuAction_End) {
        CloseHandle(prefmenu);
    }
    return 0;
}

bool IsClientInBuyZone(int client) {
    return view_as<bool>(GetEntProp(client, Prop_Send, "m_bInBuyZone"));
}

int GetClientMoney(int client) {
    return GetEntProp(client, Prop_Send, "m_iAccount");
}

void SetClientMoney(int client, int amount) {
    SetEntProp(client, Prop_Send, "m_iAccount", amount);
}

void GiveWeapon(int client, const char[] item, int clip=-1, int ammo=-1) {
    int ent = GivePlayerItem(client, item);
    if(clip != -1) {
        SetEntProp(ent, Prop_Send, "m_iClip1", clip);
    }
    if(ammo != -1) {
        int PrimaryAmmoType = GetEntProp(ent, Prop_Data, "m_iPrimaryAmmoType");

        if(PrimaryAmmoType != -1)
            SetEntProp(ent, Prop_Send, "m_iAmmo", ammo, _, PrimaryAmmoType);
    }
    if(strncmp(item, "item_", 5) != 0 && !StrEqual(item, "weapon_hegrenade", false))
        EquipPlayerWeapon(client, ent);
}