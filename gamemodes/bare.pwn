#include <a_samp> // SA-MP TEAM
#include <lib\fixes> // 14 contributors 
#include <lib\izcmd> //
#include <YSI_Storage\y_ini> // Y_Less
#include <lib\sscanf2> // madinat0r
// Macros

// Rutas
#define PATH "/players/%s.ini"

// Diálogos
enum
{
	D_REGISTER,
	D_LOGIN
};

// Variables
enum pInfo
{
	pPass,
	pCash,
	pAdmin,
	pKills,
	pDeaths
}
new PlayerInfo[MAX_PLAYERS][pInfo];


// Funciones
stock kPlayerName(playerid)
{
	new playername[MAX_PLAYER_NAME + 1];
	GetPlayerName(playerid, playername, sizeof playername);
	return playername;
}
stock kErrorMsg(playerid, const str[], const color[] = "f24d41")
{
	new string[128];
	format(string, sizeof string, "{%s}ERROR — {e8e8e8}%s.", color, str);
	SendClientMessage(playerid, -1, string);
	return 1;
}

stock kUsageMsg(playerid, const str[], const color[] = "61ab16")
{
	new string[128];
	format(string, sizeof string, "{%s}USO — {e8e8e8}%s.", color, str);
	SendClientMessage(playerid, -1, string);
	return 1;
}

stock kInfoMsg(playerid, const str[], const color[] = "edd415")
{
	new string[128];
	format(string, sizeof string, "{%s}INFO — {e8e8e8}%s.", color, str);
	SendClientMessage(playerid, -1, string);
	return 1;
}

forward LoadUser_data(playerid,name[],value[]);
public LoadUser_data(playerid,name[],value[])
{
    INI_Int("Password",PlayerInfo[playerid][pPass]);
    INI_Int("Cash",PlayerInfo[playerid][pCash]);
    INI_Int("Admin",PlayerInfo[playerid][pAdmin]);
    INI_Int("Kills",PlayerInfo[playerid][pKills]);
    INI_Int("Deaths",PlayerInfo[playerid][pDeaths]);
    return 1;
}

stock UserPath(playerid)
{
	new 
		string[32],
		playername[MAX_PLAYER_NAME]
	;
	GetPlayerName(playerid, playername, sizeof playername);
	format(string, sizeof string, PATH, playername);
	return string;
}

stock udb_hash(const buf[]) {
    new length=strlen(buf);
    new s1 = 1;
    new s2 = 0;
    new n;
    for (n=0; n<length; n++)
    {
       s1 = (s1 + buf[n]) % 65521;
       s2 = (s2 + s1)     % 65521;
    }
    return (s2 << 16) + s1;
}

stock SaveUserData(playerid)
{
	new INI:File = INI_Open(UserPath(playerid));
	INI_SetTag(File, "data");
	INI_WriteInt(File,"Cash",GetPlayerMoney(playerid));
    INI_WriteInt(File,"Admin",PlayerInfo[playerid][pAdmin]);
    INI_WriteInt(File,"Kills",PlayerInfo[playerid][pKills]);
    INI_WriteInt(File,"Deaths",PlayerInfo[playerid][pDeaths]);
    INI_Close(File);
    return 1;
}

main()
{
	print("— klaysDM");
}

public OnPlayerConnect(playerid)
{
	if (fexist(UserPath(playerid)))
	{
		INI_ParseFile(UserPath(playerid), "LoadUser_%s", .bExtra = true, .extra = playerid);
		ShowPlayerDialog(playerid, D_LOGIN, DIALOG_STYLE_INPUT, "Ingreso", "Ingresa tu password:", "Ingresar", "Salir");
	}
	else
	{
		ShowPlayerDialog(playerid, D_REGISTER, DIALOG_STYLE_INPUT, "Registro", "Ingresa tu password:", "Registrar", "Salir");
	}
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	SaveUserData(playerid);
	return 1;
}

public OnPlayerSpawn(playerid)
{
	SetPlayerInterior(playerid,0);
	TogglePlayerClock(playerid,0);
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
   	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	return 1;
}

public OnGameModeInit()
{
	SetGameModeText("Bare Script");
	ShowPlayerMarkers(1);
	ShowNameTags(1);
	AllowAdminTeleport(1);

	AddPlayerClass(265,1958.3783,1343.1572,15.3746,270.1425,0,0,0,0,-1,-1);

	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    switch(dialogid)
    {
        case D_REGISTER:
        {
            if (!response) return Kick(playerid);
            if(!strlen(inputtext)) return ShowPlayerDialog(playerid, D_REGISTER, DIALOG_STYLE_INPUT, "Registro","No ingresaste una password, vuelve a intentarlo:", "Registrar","Salir");
            new INI:File = INI_Open(UserPath(playerid));
            INI_SetTag(File,"data");
            INI_WriteInt(File,"Password",udb_hash(inputtext));
            INI_WriteInt(File,"Cash",0);
            INI_WriteInt(File,"Admin",0);
            INI_WriteInt(File,"Kills",0);
            INI_WriteInt(File,"Deaths",0);
            INI_Close(File);

            SetSpawnInfo(playerid, 0, 0, 1958.33, 1343.12, 15.36, 269.15, 0, 0, 0, 0, 0, 0);
            SpawnPlayer(playerid);
        }

        case D_LOGIN:
        {
            if (!response) return Kick (playerid);
            if(udb_hash(inputtext) == PlayerInfo[playerid][pPass])
            {
                INI_ParseFile(UserPath(playerid), "LoadUser_%s", .bExtra = true, .extra = playerid);
                GivePlayerMoney(playerid, PlayerInfo[playerid][pCash]);

                SetSpawnInfo(playerid, 0, 0, 1958.33, 1343.12, 15.36, 269.15, 0, 0, 0, 0, 0, 0);
                SpawnPlayer(playerid);
            }
            else
            {
                ShowPlayerDialog(playerid, D_LOGIN, DIALOG_STYLE_INPUT,"Ingreso","Ingresaste una password inválida. Vuelve a intentarlo:", "Ingresar","Salir");
            }
        }
    }
    return 1;
}

public OnPlayerCommandPerformed(playerid, cmdtext[], success)
{
    if(!success) return kErrorMsg(playerid, "El comando introducido no existe");
    return true;
}

// Comandos
CMD:ayuda(playerid)
{
	SendClientMessage(playerid, -1, "Menú de ayuda.");
	return 1;
}

//Admin Commands
CMD:setadmin(playerid, params[])
{
	extract params -> new player:target, level;
	if (isnull(params)) return kUsageMsg(playerid, "/setadmin [target] [nivel (1-3)]");
	if (IsPlayerConnected(target)) return kErrorMsg(playerid, "El jugador especificado no está conectado");
	if (level > 3 || level < 1) return kErrorMsg(playerid, "El nivel (segundo parámetro) debe ser mayor que uno y menor que 3");
	PlayerInfo[target][pAdmin] = level;
	new string[128];
	format(string, sizeof string, "%s te asignó el adminrank %d", kPlayerName(playerid), level);
	kInfoMsg(target, string);
	format(string, sizeof string, "Asignaste el adminrank %d a %s", level, kPlayerName(target));
	kInfoMsg(playerid, string);
	return 1;
}
CMD:clearadmin(playerid, params[])
{
	extract params -> new player:target;
	if (isnull(params)) return kUsageMsg(playerid, "/clearadmin [target]");
	if (!IsPlayerConnected(target)) return kErrorMsg(playerid, "El jugador especificado no está conectado");
	PlayerInfo[target][pAdmin] = 0;
	new string[128];
	format(string, sizeof string, "%s te limpió tus variables administrativas", kPlayerName(playerid));
	kInfoMsg(target, string);
	format(string, sizeof string, "Limpiaste las variables administrativas de %s", kPlayerName(target));
	kInfoMsg(playerid, string);
	return 1;
}