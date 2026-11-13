import java.io.*;
import java.lang.reflect.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;

// Runs a Lua file (a sim) in the game's own Kahlua VM, where strings are Java strings: one Lua character per UTF-16
// unit, string.char takes code points, and next() does not exist. A sim that passes on real Lua 5.1 can still fail in
// the game; this runs it the game's way. Never starts the game.
//
// Reflection only: the game's classes are built for a newer Java than this compiles with, and KCheck.java (beside
// it) works the same way. Compile once with any JDK (C:/Program Files/Java/jdk-19/bin/javac -d <dir> KRun.java) and
// run it with the game's own Java, from anywhere:
//   "<game>/jre64/bin/java" -Duser.dir="<game>" -cp "<dir>;<game>/projectzomboid.jar" KRun <sim, absolute> [args...]
// (Kahlua loads its stdlib.lua from the working folder, which -Duser.dir points at the game's; so give every path
// whole.) The sim gets arg[1..] and two globals: kread(path), the file's text (UTF-8) or nil, and kload(path), the
// file compiled as a chunk (like loadfile). It sets KRUN_EXIT to the exit code it wants; an error exits 2.
public class KRun {
    static Object env;
    static Method loadisReader;

    static Object compile(String path) throws Exception {
        try (Reader r = new InputStreamReader(new FileInputStream(path), StandardCharsets.UTF_8)) {
            return loadisReader.invoke(null, r, new File(path).getName(), env);
        }
    }

    public static void main(String[] args) throws Exception {
        Class<?> platC = Class.forName("se.krka.kahlua.j2se.J2SEPlatform");
        Class<?> platI = Class.forName("se.krka.kahlua.vm.Platform");
        Class<?> tableC = Class.forName("se.krka.kahlua.vm.KahluaTable");
        Class<?> threadC = Class.forName("se.krka.kahlua.vm.KahluaThread");
        Class<?> compC = Class.forName("se.krka.kahlua.luaj.compiler.LuaCompiler");
        Class<?> jfC = Class.forName("se.krka.kahlua.vm.JavaFunction");
        Class<?> frameC = Class.forName("se.krka.kahlua.vm.LuaCallFrame");
        Object platform = platC.getConstructor().newInstance();
        env = platC.getMethod("newEnvironment").invoke(platform);
        Object thread = threadC.getConstructor(PrintStream.class, platI, tableC).newInstance(System.out, platform, env);
        // (the game's fork checks which Java thread owns the Lua thread on every pcall)
        threadC.getField("debugOwnerThread").set(thread, Thread.currentThread());
        loadisReader = compC.getMethod("loadis", Reader.class, String.class, tableC);
        final Method fget = frameC.getMethod("get", int.class);
        final Method fpush1 = frameC.getMethod("push", Object.class);
        final Method fpush2 = frameC.getMethod("push", Object.class, Object.class);
        final Method fpushNil = frameC.getMethod("pushNil");
        Method rawset = tableC.getMethod("rawset", Object.class, Object.class);
        Method rawget = tableC.getMethod("rawget", Object.class);

        // (a Lua-callable Java function, made without compiling against the game's interface)
        Object kread = Proxy.newProxyInstance(jfC.getClassLoader(), new Class<?>[] { jfC }, (proxy, m, a) -> {
            if (!m.getName().equals("call")) return m.getName().equals("hashCode") ? 1 : (m.getName().equals("toString") ? "kread" : Boolean.FALSE);
            Object frame = a[0];
            String p = String.valueOf(fget.invoke(frame, 0));
            try {
                return fpush1.invoke(frame, new String(Files.readAllBytes(Paths.get(p)), StandardCharsets.UTF_8));
            } catch (IOException e) {
                return fpushNil.invoke(frame);
            }
        });
        Object kload = Proxy.newProxyInstance(jfC.getClassLoader(), new Class<?>[] { jfC }, (proxy, m, a) -> {
            if (!m.getName().equals("call")) return m.getName().equals("hashCode") ? 2 : (m.getName().equals("toString") ? "kload" : Boolean.FALSE);
            Object frame = a[0];
            String p = String.valueOf(fget.invoke(frame, 0));
            try {
                return fpush1.invoke(frame, compile(p));
            } catch (Exception e) {
                Throwable t = (e instanceof InvocationTargetException) ? e.getCause() : e;
                return fpush2.invoke(frame, null, "kload: " + t);
            }
        });
        rawset.invoke(env, "kread", kread);
        rawset.invoke(env, "kload", kload);
        Object argt = platC.getMethod("newTable").invoke(platform);
        for (int i = 1; i < args.length; i++) rawset.invoke(argt, (double) i, args[i]);
        rawset.invoke(env, "arg", argt);
        Object c = compile(args[0]);
        Object[] res = (Object[]) threadC.getMethod("pcall", Object.class, Object[].class).invoke(thread, c, new Object[0]);
        if (res.length > 0 && Boolean.FALSE.equals(res[0])) {
            System.out.println("KRUN ERROR: " + (res.length > 1 ? res[1] : "?"));
            for (int i = 2; i < res.length; i++) System.out.println(res[i]);
            System.exit(2);
        }
        Object code = rawget.invoke(env, "KRUN_EXIT");
        System.exit(code instanceof Double ? ((Double) code).intValue() : 0);
    }
}
