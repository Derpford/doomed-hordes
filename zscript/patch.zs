class HordePatchService : Service {
    // Exists to alter horde spawner behavior.
    Map<Name,Name> replacements; // Holds custom replacement logic. Key is replaced by Value.

    Map<Name,Int> replacetypes; // Overrides replacement type for some things, i.e., to ensure that CustomInventory keys are treated like keys.

    Name PickSpawner(Name replacee) {
        // Picks a type to spawn.
        if (replacements.CheckKey(replacee)) {
            // Hard replacement found.
            return replacements.Get(replacee);
        }
        
        // Otherwise, just use the regular return.
        return replacee;
    }

    override String GetString(String command, String strArg, int intArg, double dArg, Object objArg) {
        if (command == "addreplacement") {
            return AddReplacement(strArg);
        }

        if (command == "getreplacement") {
            return PickSpawner(strArg);
        }

        Console.printf("\cgInvalid command \"%s\" passed to HordePatchService.",command);
        return "";
    }

    String AddReplacement(String input) {
        Array<String> parsed;
        input.Split(parsed,",");
        if (parsed.size() < 2) {
            Console.printf("\cgAddReplacement: Incorrectly formatted argument \"%s\". Argument should take the form of \"Thing,Replacement\".",input);
            return "";
        }

        replacements.insert(parsed[0],parsed[1]);
        return parsed[1];
    }

}