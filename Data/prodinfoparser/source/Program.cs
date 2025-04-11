using System.Globalization;
using System.Text;

namespace ProdinfoParser;

public abstract class Program
{
    public static void Main(string[] args)
    {
     //  args =
      //  [
        //   "/home/hana/Desktop/Prodinfo_injector/prod.info", "/home/hana/Desktop/Prodinfo_injector/Data/Offsets.csv",
        //   "true"
       // ];


        if (args.Length != 3)
        {
            Console.WriteLine("args: prod.info_path offsets_path bool:getDeviceId");
            return;
        }
        
        var prodinfoPath = "";
        var offsetsPath = "";
        var getDeviceId = false;

        try
        {
            prodinfoPath = args[0].Replace("\"", "");
            offsetsPath = args[1].Replace("\"", "");
            getDeviceId = args[2] == "true";
            if (!File.Exists(prodinfoPath) || !File.Exists(offsetsPath))
                throw new Exception("File paths are invalid! "+prodinfoPath);
        }
        catch (Exception e)
        {
            Console.WriteLine(e.Message);
            return;
        }

        
        List<ProdinfoPart> prodinfoParts = [];
        var prodinforead = File.ReadAllBytes(prodinfoPath);

        if (getDeviceId)
        {
            var deviceId = "";
            try
            {
                for (var index = 0; index < prodinforead.Length; index++)
                {
                    if (prodinforead[index] != 0x4E || prodinforead[index + 1] != 0x58 ||
                        prodinforead[index + 18] != 0x2D) continue;
                    //Console.WriteLine("Found device ID!");
                    deviceId = Encoding.ASCII.GetString(prodinforead, index+2, 16);
                    deviceId = "0x00" + deviceId[2..] + "u;";
                    Console.WriteLine(deviceId);
                    break;
                }

                if (deviceId.Length != 20)
                {
                    throw new Exception("Device ID not found!");
                }
                return;
            }
            catch (Exception e)
            {
                Console.WriteLine(e.Message);
                throw;
            }
                
        }
        
        
        
        
        
        //Console.WriteLine(prodinforead.Length);
        var lines = File.ReadLines(offsetsPath);
        foreach (var line in lines)
        {
            var parts = line.Split(',');
            prodinfoParts.Add(new ProdinfoPart
            {
                offset = uint.Parse(parts[0][2..], NumberStyles.HexNumber),
                size = uint.Parse(parts[1][2..], NumberStyles.HexNumber),
                name = parts[2]
            });
        }

        // Console.WriteLine(GenerateCWrite(0x20u,213));
        var amsCGenerator = new StringBuilder();
        foreach (var pinfPart in prodinfoParts)
            //Console.WriteLine($@"{pinfPart.name}: Offset: {pinfPart.offset}, Size: {pinfPart.size}");
            for (var index = pinfPart.offset; index < pinfPart.offset + pinfPart.size; index++)
            {
                var byteOut = prodinforead[index];
                amsCGenerator.Append(GenerateCWrite(index, byteOut));
            }

        //Console.WriteLine("Total critical elements: "+prodinfoParts.Count);
        Console.WriteLine("unsigned int start_writing_prodinfo = 0;");
        Console.WriteLine(amsCGenerator.ToString());
        Console.WriteLine("unsigned int finish_writing_prodinfo = 0;");
        Console.WriteLine("finish_writing_prodinfo += start_writing_prodinfo;");
    }

    public static string GenerateCWrite(uint offset, byte byteOut)
    {
        return $"prodInfoWritePtr=prodInfoPtr+{offset};\n*prodInfoWritePtr=0x{byteOut:X2}u;\n";
    }

    private struct ProdinfoPart
    {
        public uint offset;
        public uint size;
        public string name;
    }
}
