# The Doomed Hordes

Automatic hordemode support for any map!

## How it Works

On map start, for about 10 tics, all actors with +SHOOTABLE and all actors of type Inventory are given a special spawner. This spawner stores the class of item it spawns.

Then, every couple of minutes, it tells most of those spawners to respawn their things. If there are any keys in the map, after three waves, it triggers a random key to spawn.

In other words: Every couple of minutes, a whole bunch of monsters respawn and all the ammo/health/armor/etc does too.