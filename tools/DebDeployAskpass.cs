using System;

// ssh reads the answer through a pipe. No password is stored in this binary.
internal static class DebDeployAskpass
{
    private static int Main()
    {
        string password = Environment.GetEnvironmentVariable("NVIM_DEBDEPLOY_PASSWORD");
        if (password == null) return 1;
        Console.WriteLine(password);
        return 0;
    }
}
