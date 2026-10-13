import java.io.*;
import java.lang.reflect.*;

// Compiles (parses) each Lua file with the game's Kahlua compiler via reflection. Never executes the chunk.
public class KCheck {
    public static void main(String[] args) throws Exception {
        Class<?> lc = Class.forName("se.krka.kahlua.luaj.compiler.LuaCompiler");
        Class<?> kt = Class.forName("se.krka.kahlua.vm.KahluaTable");
        Method m = lc.getMethod("loadis", InputStream.class, String.class, kt);
        int bad = 0;
        for (String path : args) {
            try (InputStream in = new FileInputStream(path)) {
                m.invoke(null, in, new File(path).getName(), null);
                System.out.println("OK    " + path);
            } catch (InvocationTargetException e) {
                bad++;
                System.out.println("FAIL  " + path + "  ->  " + e.getCause());
            } catch (Throwable t) {
                bad++;
                System.out.println("FAIL  " + path + "  ->  " + t);
            }
        }
        System.out.println(bad == 0 ? "ALL PARSED" : (bad + " FAILED"));
    }
}
