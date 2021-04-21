#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <collisionhook>

#pragma newdecls required

#define DEBUG

ArrayList g_pGrenadeRef;
ArrayList g_pGrenadeTeam;

public Plugin myinfo = 
{
	name = "No Team Grenades Block",
	author = "kRatoss",
	description = "Prevent grenades to get blocked by teammates.",
	version = "1.1"
};

public void OnPluginStart()
{
	g_pGrenadeRef = new ArrayList(32);
	g_pGrenadeTeam = new ArrayList(32);
	
	g_pGrenadeRef.Clear();
	g_pGrenadeTeam.Clear();
}

public void OnMapStart()
{
	// Empty the list of grenades when the map starts.
	g_pGrenadeRef.Clear();
	g_pGrenadeTeam.Clear();
}

public void OnMapEnd()
{
	// Empty the list of grenades when the map ends.
	g_pGrenadeRef.Clear();
	g_pGrenadeTeam.Clear();
}

public void OnEntityCreated(int entity, const char[] classname)
{
	// Make sure the entity is valid.
	if(entity > MaxClients && IsValidEdict(entity) && IsValidEntity(entity))
	{
		// Make sure the entity is a grenade such as 'smokegrenade_projectile', 'hegrenade_projectile', etc..
		if(StrContains(classname, "_projectile", false) != -1)
		{
			// Hook the spawn, since now it's too early to get it's owner.
			SDKHook(entity, SDKHook_SpawnPost, SDK_OnEntitySpawnPost);
		}
	}
}

public void OnEntityDestroyed(int entity)
{
	// Make sure the entity is valid.
	if(entity > MaxClients && IsValidEdict(entity) && IsValidEntity(entity))
	{
		int index = g_pGrenadeRef.FindValue(EntIndexToEntRef(entity));
		// Remove grenade entry from arraylist.
		if(index != -1)
		{
			g_pGrenadeRef.Erase(index);
			g_pGrenadeTeam.Erase(index);	
		}
	}
}

public void SDK_OnEntitySpawnPost(int entity)
{
	// Make sure the entity still exists.
	if (entity < -1)
	{
		entity = EntRefToEntIndex(entity);
		if (entity == INVALID_ENT_REFERENCE)
			return;
	}

	// Save the entity reference.
	g_pGrenadeRef.Push(EntIndexToEntRef(entity));
	
	// Save the team of grenade's owner.
	g_pGrenadeTeam.Push(GetClientTeam(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")));
}

public Action CH_PassFilter(int ent1, int ent2, bool &result)
{
	// We declar classname & index as static. 
	// This will optimize speed, because the variable is not allocated multiple times (Credits: https://forums.alliedmods.net/member.php?u=85778)
	static char classname[64] = "";
	static int index = -1;
	GetEntityClassname(ent2, classname, sizeof(classname));
	
	// Make sure the entity is a grenade such as 'smokegrenade_projectile', 'hegrenade_projectile', etc..
	if(StrContains(classname, "_projectile", false) != -1)
	{
		// Make sure the entity is a player.
		if(ent1 > 0 && ent1 <= MaxClients && IsClientInGame(ent1))
		{
			// Check if the grenade collided with a teammate.
			index = g_pGrenadeRef.FindValue(EntIndexToEntRef(ent2));
			if(index != -1 && g_pGrenadeTeam.Get(index) == GetClientTeam(ent1))
			{
				// Modify the result.
				result = false;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}