class Debug {
    // Handy utility for turning all debug prints on or off.

    static void Log(String txt) {
        // CVar debug = CVar.GetCVar("cl_debug");
        // bool db = debug.GetBool();
        if (true) {
            console.printf("\cg"..txt);
        }
    }
}