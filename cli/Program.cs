using MarkItDown;
using System.Text;

if (args.Length == 0 || args[0] is "-h" or "--help")
{
    Console.Error.WriteLine("Usage: managedcodemd-convert <file-path-or-url>");
    Console.Error.WriteLine("       cat notes.txt | managedcodemd-convert -");
    return args.Length == 0 ? 1 : 0;
}

var input = args[0];
var client = new MarkItDownClient();

try
{
    DocumentConverterResult result;

    if (input == "-")
    {
        var text = await Console.In.ReadToEndAsync();
        await using var stream = new MemoryStream(Encoding.UTF8.GetBytes(text));
        result = await client.ConvertAsync(stream, new StreamInfo(extension: ".txt", mimeType: "text/plain", fileName: "stdin.txt"));
    }
    else if (input.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
        input.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
    {
        result = await client.ConvertFromUrlAsync(input);
    }
    else
    {
        if (!File.Exists(input))
        {
            Console.Error.WriteLine($"File not found: {input}");
            return 1;
        }
        result = await client.ConvertAsync(input);
    }

    await using (result)
    {
        Console.Write(result.Markdown);
    }

    return 0;
}
catch (Exception ex)
{
    Console.Error.WriteLine($"Conversion failed: {ex.Message}");
    return 1;
}
