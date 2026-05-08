using DocSharp.Binary.DocFileFormat;
using DocSharp.Binary.OpenXmlLib;
using DocSharp.Binary.OpenXmlLib.WordprocessingML;
using DocSharp.Binary.StructuredStorage.Reader;
using DocSharp.Binary.WordprocessingMLMapping;
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
var tempDocxDirectory = "";

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

        var conversionInput = input;
        if (Path.GetExtension(input).Equals(".doc", StringComparison.OrdinalIgnoreCase))
        {
            (conversionInput, tempDocxDirectory) = ConvertLegacyDocToDocx(input);
        }

        result = await client.ConvertAsync(conversionInput);
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
finally
{
    if (!string.IsNullOrEmpty(tempDocxDirectory) && Directory.Exists(tempDocxDirectory))
    {
        try
        {
            Directory.Delete(tempDocxDirectory, recursive: true);
        }
        catch
        {
            // Do not fail an otherwise successful conversion because temp cleanup failed.
        }
    }
}

static (string DocxPath, string TempDirectory) ConvertLegacyDocToDocx(string input)
{
    var tempDirectory = Path.Combine(Path.GetTempPath(), $"managedcodemd-doc-{Guid.NewGuid():N}");
    Directory.CreateDirectory(tempDirectory);

    var outputFileName = $"{Path.GetFileNameWithoutExtension(input)}.docx";
    var outputPath = Path.Combine(tempDirectory, outputFileName);

    using var storage = new StructuredStorageReader(input);
    var document = new WordDocument(storage, 0);
    using var docx = WordprocessingDocument.Create(outputPath, WordprocessingDocumentType.Document);

    Converter.Convert(document, docx);
    docx.Close();

    return (outputPath, tempDirectory);
}
