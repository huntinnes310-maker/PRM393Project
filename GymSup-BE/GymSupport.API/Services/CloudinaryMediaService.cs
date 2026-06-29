using CloudinaryDotNet;
using CloudinaryDotNet.Actions;

namespace GymSupport.API.Services;

public sealed class CloudinaryMediaService
{
    private readonly IConfiguration _configuration;

    public CloudinaryMediaService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public async Task<(string SecureUrl, string PublicId, string ResourceType)> UploadAsync(
        IFormFile file,
        string resourceType,
        CancellationToken cancellationToken)
    {
        var cloudName = _configuration["Cloudinary:CloudName"];
        var apiKey = _configuration["Cloudinary:ApiKey"];
        var apiSecret = _configuration["Cloudinary:ApiSecret"];

        if (string.IsNullOrWhiteSpace(cloudName) ||
            string.IsNullOrWhiteSpace(apiKey) ||
            string.IsNullOrWhiteSpace(apiSecret))
        {
            throw new InvalidOperationException("Cloudinary chưa được cấu hình trên server.");
        }

        var cloudinary = new Cloudinary(new Account(cloudName, apiKey, apiSecret))
        {
            Api = { Secure = true }
        };

        await using var stream = file.OpenReadStream();
        var fileDescription = new FileDescription(file.FileName, stream);

        UploadResult result;
        if (resourceType == "video")
        {
            result = await cloudinary.UploadAsync(
                new VideoUploadParams
                {
                    File = fileDescription,
                    Folder = "gym-support/exercises/videos",
                    UseFilename = true,
                    UniqueFilename = true,
                    Overwrite = false
                },
                cancellationToken);
        }
        else
        {
            result = await cloudinary.UploadAsync(
                new ImageUploadParams
                {
                    File = fileDescription,
                    Folder = "gym-support/exercises/images",
                    UseFilename = true,
                    UniqueFilename = true,
                    Overwrite = false
                },
                cancellationToken);
        }

        if (result.Error != null)
        {
            throw new InvalidOperationException(result.Error.Message);
        }

        return (result.SecureUrl.ToString(), result.PublicId, resourceType);
    }
}
