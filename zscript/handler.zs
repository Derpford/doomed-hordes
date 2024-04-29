class HordeModeHandler : EventHandler {
    int tics;
    int seconds;
    // How long since level start?
    int wavetime; // How many seconds to next wave.

    int wave;

    Array<Actor> spawns;

    Array<Actor> keyspawns;

    override void WorldTick() {
        // Set timer.
        wavetime = CVar.GetCVar("horde_wavetime").GetInt();
        // Increment timer.
        tics += 1;
        if (tics % 35 == 0) {
            seconds += 1;
            int timeleft = wavetime - seconds;
            switch (timeleft) {
                default:
                    break;    

                case 3:
                case 2:
                case 1:
                    String msg = String.Format("Next Wave in %d...",timeleft);
                    players[0].mo.A_PrintBold(msg,1.0,"BIGFONT");
                    break;

                case 0:
                    WaveStart();
                    seconds = 0;
                    break;
            }
        }

    }

    override void WorldThingSpawned(WorldEvent e) {
        String cname = e.Thing.GetClassName();
        if (cname.IndexOf("Fake") >= 0) { return; } // Brutal Doom Platinum compat
        if (tics >= 10) { return; } // Out of time!
        if (e.Thing is "PlayerPawn") { return; } // Players don't count.
        if (e.Thing.bSHOOTABLE || (e.Thing is "Inventory" && e.Thing.pos != (0,0,0))) {
            console.printf("Making a spawner for %s",e.Thing.GetTag());

            if (e.Thing is "Key") {
                WaveSpawnPoint sp = WaveSpawnPoint(e.Thing.Spawn("WaveSpawnPoint",e.Thing.pos));
                if (sp) {
                    sp.type = e.Thing.GetClass();
                    sp.healthgoal = 0;
                    keyspawns.push(sp);
                }
                Inventory inv = Inventory(e.Thing);
                inv.Destroy();
            } else {
                if (!(e.Thing is "WaveSpawnPoint")) {
                    // This is a valid thing to create a spawnpoint for.
                    int hgoal = 0;
                    if (e.Thing.bSHOOTABLE) { hgoal = e.Thing.Health; }
                    WaveSpawnPoint sp = WaveSpawnPoint(e.Thing.Spawn("WaveSpawnPoint",e.Thing.pos));
                    if (sp) {
                        sp.type = e.Thing.GetClass();
                        sp.healthgoal = hgoal;
                        sp.angle = e.Thing.angle;
                        sp.current = e.Thing;
                        spawns.push(sp);
                    }
                }
            }
        }

    }

    void WaveStart() {
        wave++;

        console.printf("Wave %d",wave);

        foreach (obj : spawns) {
            WaveSpawnPoint sp = WaveSpawnPoint(obj); if (sp) {
                sp.CueSpawn(random(20,60) + (random(10,20) * wave));
                // By this logic, ammo and the standard zombieman spawn every wave.
                // There is a chance for an imp to spawn in a single wave, but it'll usually happen every 2-3 waves.
                // The rate at which larger monsters appear increases over time, and smaller monsters will start spawning every wave
                // because their healthbuffer grows faster than they can consume it.
            }
        }

        if (keyspawns.size() > 0 && wave > 3 && wave % 3 == 1) { // at the end of every 3 waves
            int i = random(0,keyspawns.size()-1);
            WaveSpawnPoint k = WaveSpawnPoint(keyspawns[i]);
            k.CueSpawn(999);
            Class<Actor> t = k.type; 
            let it = GetDefaultByType(t);
            String tag = it.GetTag();
            Class<Actor> itc = it.species;
            if (itc) {
                let itspec = GetDefaultByType(itc);
                tag = itspec.GetTag();
            }
            k.A_PrintBold(String.Format("The %s has spawned",tag),3.0,"BIGFONT");
            keyspawns.delete(i); // Can't spawn the same key twice. Doom's keys aren't consumable!

        }
    }

    override void RenderOverlay(RenderEvent e) {
        PlayerPawn plr = players[consoleplayer].mo;
        StatusBar.BeginHud(); // Gross hax ahead!
        HUDFont confont = HUDFont.Create("SMALLFONT");
        HUDFont bigfont = HUDFont.Create("BIGFONT");
        int flags = StatusBar.DI_TEXT_ALIGN_CENTER|StatusBar.DI_ITEM_CENTER|StatusBar.DI_ITEM_VCENTER|StatusBar.DI_SCREEN_TOP|StatusBar.DI_SCREEN_HCENTER;
        int bflags = StatusBar.DI_TEXT_ALIGN_CENTER|StatusBar.DI_ITEM_CENTER|StatusBar.DI_ITEM_VCENTER|StatusBar.DI_SCREEN_BOTTOM|StatusBar.DI_SCREEN_HCENTER;
        // Score...
        StatusBar.DrawString(confont,String.Format("%d",plr.score),
            (0,48),bflags,Font.CR_WHITE);
        // Wave Count...
        StatusBar.DrawString(bigfont,String.Format("Wave %d",wave),
            (0,48),flags,Font.CR_WHITE);
        // Timer...
        StatusBar.DrawString(bigfont,String.Format("%d",wavetime - seconds),
            (0,64),flags,Font.CR_WHITE);
    }
}

class WaveSpawnPoint : Actor {
    Class<Actor> type;

    Actor current;

    int healthgoal;
    int healthbuffer; // Each CueSpawn call adds to this. When it's higher than healthgoal, spawn the monster.
    bool spawncued;
    int spawntics; // How long until we spawn the thing. Used to create a random offset between spawns.

    default {
        RenderStyle "Add";
        Alpha 0.3;
        Scale 0.5;
    }

    override void PostBeginPlay() {
        if (type) {
            let defs = GetDefaultByType(type);
            TextureID id; bool success; vector2 newscale;
            [id,success,newscale] = defs.ResolveState("Spawn").GetSpriteTexture(0);

            picnum = id;
            scale = newscale * 0.5;
        }
    }

    void CueSpawn(int amt) {
        if (current) {
            if (current.bSHOOTABLE && current.health <= 0) {
            } else {
                return; // Only one copy of the thing at a time.
            }
        }
        if (healthgoal >= 0) {
            healthbuffer = min(int.MAX,healthbuffer+amt); // overflow protection
            if (healthbuffer > healthgoal) {
                healthbuffer -= healthgoal;
                spawncued = true;
            }
        } else {
            spawncued = true;
        }

        if (spawncued) {
            // Randomize spawn queue time.
            spawntics = random(1,15);
        }
    }

    override void Tick() {
        super.Tick();
        if (spawncued && (type is "Inventory" || !CheckIfSeen())) {
            spawntics--;
            if (spawntics <= 0) {
                spawncued = false;
                let it = Spawn(type,pos);
                it.angle = angle;
                if (it && healthgoal <= 0 && !(type is "Key")) {
                    it.vel += (frandom(-2,2),frandom(-2,2),frandom(0,4));
                }
                current = it;
                Spawn("TeleportFog",pos);
            }
        }
    }
}