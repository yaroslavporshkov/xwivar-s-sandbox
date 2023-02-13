//===================================[INCLUDES]===================================
#include <a_samp>
#include <a_mysql>
#include <sscanf2>
#include <fmt>
#include <fix_Kick>
//#include "../gamemodes/Code/Localization/init.inc"
//===================================[FUNCTIONS]===================================
#define CompareString !strcmp
//===================================[COLORS]===================================
#define COLOR_ERROR_HEX "EB0501"
#define COLOR_ERROR_RGBA 0xEB0501FF
#define COLOR_SANDBOX_HEX "EA6800"
#define COLOR_SANDBOX_RGBA 0xEA6800FF
#define COLOR_MESSAGE_HEX "FFFFFF"
#define COLOR_MESSAGE_RGBA 0xEA6800FF
//===================================[PLAYERINFO]===================================
enum PlayerInfo
{
	pID,
	pName[MAX_PLAYER_NAME],
    bool:pLogged,
	pHash[65],
 	pSalt[11],
 	pLanguage,
	pRegIP[16],
	pCurrentIP[16],
	pAdmin
	
};
new PI[MAX_PLAYERS][PlayerInfo];
//===================================[MYSQL]===================================
#define SQL_HOST        "51.91.215.125"
#define SQL_USER        "gs189460"
#define SQL_DB          "gs189460"
#define SQL_PASS        "szLJVKaKshlG"
new MySQL:mysql_samp;
//===================================[OTHER]===================================
enum _:DialogList
{
	dialog_null,
	dialog_register_language,
	dialog_register_password,
	dialog_authorization

}
stock ShowRegistrationLanguageDialog(playerid)
{
	ShowPlayerDialog(playerid, 
	dialog_register_language, 
	DIALOG_STYLE_LIST, 
	"Выбор языка",
	"Русский язык",
	"Выбор", "");
    return 1;
}
stock ShowRegistrationPasswordDialog(playerid)
{
	ShowPlayerDialogf(playerid, 
    dialog_register_password, 
    DIALOG_STYLE_INPUT, 
    "Регистрация", 
    "Далее", 
    "Назад", 
    "{FFFFFF}Добро пожаловать, {"COLOR_SANDBOX_HEX"}%s{FFFFFF}!\n\
    Введите свой пароль ниже\n\
    Требования для пароля:\n\
    \tПароль может состоять только из символов латинского алфавита и цифр\n\
    \tПароль должен быть не короче 8 и не длинее 32 символов", 
    PI[playerid][pName]);
    return 1;
}

stock ShowRegistrationGenderDialog(playerid)
{
	ShowPlayerDialogf(playerid, 
    dialog_register_gender, 
    DIALOG_STYLE_LIST, 
    "Регистрация",
    "{FFFFFF}Мужчина\n\
	Женщина", 
    PI[playerid][pName],
	"Выбор",
	"Назад");
    return 1;
}

stock ShowAuthorizationDialog(playerid)
{
	ShowPlayerDialogf(playerid, 
    dialog_authorization, 
    DIALOG_STYLE_INPUT, 
    "Авторизация",
    "Далее", 
    "Выход", 
    "{FFFFFF}Добро пожаловать, {"COLOR_SANDBOX_HEX"}%s{FFFFFF}!\n\
    Введите свой пароль ниже.", 
    PI[playerid][pName]);
	return 1;
}

stock ConnectMySQL()
{
    mysql_samp = mysql_connect(SQL_HOST, SQL_USER, SQL_PASS, SQL_DB);
    if(mysql_errno(mysql_samp))
    {
        printf("MySQL connection succesful!");
    }
    else
    {
	    printf("MySQL connection failed! Error: %s", mysql_errno(mysql_samp));
    }
    return 1;
}

stock DisconnectMySQL()
{
    mysql_close(mysql_samp);
    return 1;
}

stock SaveAccount(playerid)
{
	mysql_format(mysql_samp, query, sizeof(query), 
	"UPDATE `users` SET\
	`username` = %e, `hash` = %e, `salt` = %e, `language` = %i,\
	WHERE `id` = %i", 
	PI[playerid][pName], PI[playerid][pHash], PI[playerid][pSalt], PI[playerid][pLanguage],
	PI[playerid][pID]);
	mysql_tquery(mysql_samp, query);
	return 1;
}

forward LoadAccount(playerid);
public LoadAccount(playerid)
{
	cache_get_value_name_int(0, "id", PI[playerid][pID]);
	cache_get_value_name_int(0, "language", PI[playerid][pLanguage]);
	cache_get_value_name(0, "regip", PI[playerid][pRegIP]);
	return 1;
}

stock InitializeAccount(playerid)
{
	new query[128];
    mysql_format(mysql_samp, query, sizeof(query), "SELECT * FROM `users` WHERE `username` = '%e'", PI[playerid][pName]);
    mysql_tquery(mysql_samp, query, "LoadAccount", "i", playerid);
	PI[playerid][pLogged] = true;
	SpawnPlayer(playerid);
	return 1;
} 

stock RegisterAccount(playerid)
{
	new query[256];
	GetPlayerIp(playerid, PI[playerid][pRegIP], 16);

	mysql_format(mysql_samp, query, sizeof(query), 
	"INSERT INTO `users` (`username`, `hash`, `salt`, `language`, `regip`) VALUES ('%e', '%e', '%e', '%i', '%e')", 
	PI[playerid][pName], PI[playerid][pHash], PI[playerid][pSalt], PI[playerid][pLanguage], PI[playerid][pRegIP]);

	mysql_tquery(mysql_samp, query);
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    for(new i; i < strlen(inputtext); i++)
    {

        switch(inputtext[i])
        {
			case '%', '{', '}': inputtext[i]=' ';
        }
    }
    switch(dialogid)
	{
	    case dialog_null: return 1;
        case dialog_register_language:
        {
	        if(!response)
	        {
		        ShowRegistrationLanguageDialog(playerid);
		        return 1;
    	    }
			if(listitem == 1)
			{
				SendClientMessage(playerid, -1, "Переклад сервера на українську мову не готовий, тому більшість діалогів/повідомлень ви побачите російською");
			}
	        PI[playerid][pLanguage] = listitem;
	        ShowRegistrationPasswordDialog(playerid);
            return 1;
        }
		case dialog_register_password:
        {
            if(!response)
	        {
	        	ShowRegistrationLanguageDialog(playerid);
	        	return 1;
	        }
	        if(!(8 <= strlen(inputtext) <= 32))
	        {
                SendClientMessage(playerid, -1, "{"COLOR_ERROR_HEX"}[!]{"COLOR_MESSAGE_HEX"} Пароль должен быть не короче 8 и не длинее 32 символов");
                ShowRegistrationPasswordDialog(playerid);
                return 1;
	        }
	        for(new i = 0; i < strlen(inputtext); i++)
	        {
            	switch(inputtext[i])
            	{
            		case 'A'..'Z', 'a'..'z', '0'..'9': continue;
		        	default:
		        	{
		        		SendClientMessage(playerid, -1, "{"COLOR_ERROR_HEX"}[!]{"COLOR_MESSAGE_HEX"} Пароль может состоять только из символов латинского алфавита и цифр");
                   	    ShowRegistrationPasswordDialog(playerid);
                   	    return 1;
		        	}
		        }
	        }
            for(new i; i < 10; i++)
            {
            	PI[playerid][pSalt][i] = random(79) + 47;
	        }
			PI[playerid][pSalt][10] = 0;
            SHA256_PassHash(inputtext, PI[playerid][pSalt], PI[playerid][pHash], 65);
	 		RegisterAccount(playerid);
			InitializeAccount(playerid);
            return 1;
        }

		case dialog_authorization:
		{
			if(!response || strlen(inputtext) == 0)ShowAuthorizationDialog(playerid);
			new hash[65];
			SHA256_PassHash(inputtext, PI[playerid][pSalt], hash, sizeof(hash));
			if(CompareString(hash, PI[playerid][pHash]))
			{
				InitializeAccount(playerid);
			}
			else
			{
				ShowAuthorizationDialog(playerid);
			}
			return 1;
		}
	}
	return 1;
}

main()
{
	print("\n----------------------------------");
	print(" Blank Gamemode by your name here");
	print("----------------------------------\n");
}

public OnGameModeInit()
{
	ConnectMySQL();
	AddPlayerClass(0, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
	return 1;
}

public OnGameModeExit()
{
    DisconnectMySQL();
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	SetPlayerPos(playerid, 1958.3783, 1343.1572, 15.3746);
	SetPlayerCameraPos(playerid, 1958.3783, 1343.1572, 15.3746);
	SetPlayerCameraLookAt(playerid, 1958.3783, 1343.1572, 15.3746);
	return 0;
}



public OnPlayerConnect(playerid)
{
	GetPlayerName(playerid, PI[playerid][pName], MAX_PLAYER_NAME);
    SetPlayerName(playerid, "_____authorization_____");
    new query[128];
    mysql_format(mysql_samp, query, sizeof(query), "SELECT `hash`, `salt` FROM `users` WHERE `username` = '%e'", PI[playerid][pName]);
    mysql_tquery(mysql_samp, query, "_OnPlayerConnect", "i", playerid);
	return 1;
}

forward _OnPlayerConnect(playerid);
public _OnPlayerConnect(playerid)
{
	new rowscount;
	cache_get_row_count(rowscount);
    if(rowscount == 1)
    {
		cache_get_value_name(0, "hash", PI[playerid][pHash]);
		cache_get_value_name(0, "salt", PI[playerid][pSalt]);
        ShowAuthorizationDialog(playerid);
    }
	else if (rowscount == 0)
	{
		ShowRegistrationLanguageDialog(playerid);
	}
	else
	{
		SendClientMessage(playerid, -1, "Какого хуя блять");
		Kick(playerid);
	}
	return 1;
}



public OnPlayerDisconnect(playerid, reason)
{
	return 1;
}

public OnPlayerSpawn(playerid)
{
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
	return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
	return 1;
}

public OnPlayerText(playerid, text[])
{
	return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
	return 1;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveCheckpoint(playerid)
{
	return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveRaceCheckpoint(playerid)
{
	return 1;
}

public OnRconCommand(cmd[])
{
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	return 1;
}

public OnObjectMoved(objectid)
{
	return 1;
}

public OnPlayerObjectMoved(playerid, objectid)
{
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
	return 1;
}

public OnVehicleMod(playerid, vehicleid, componentid)
{
	return 1;
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
	return 1;
}

public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
	return 1;
}

public OnPlayerSelectedMenuRow(playerid, row)
{
	return 1;
}

public OnPlayerExitedMenu(playerid)
{
	return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	return 1;
}

public OnRconLoginAttempt(ip[], password[], success)
{
	return 1;
}

public OnPlayerUpdate(playerid)
{
	return 1;
}

public OnPlayerStreamIn(playerid, forplayerid)
{
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid)
{
	return 1;
}

public OnVehicleStreamOut(vehicleid, forplayerid)
{
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	return 1;
}