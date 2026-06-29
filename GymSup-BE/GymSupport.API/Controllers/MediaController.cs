using GymSupport.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GymSupport.API.Controllers;

[ApiController]
[Route("api/media")]
[Authorize]
public sealed class MediaController : ControllerBase
{
    private static readonly HashSet<string> ImageTypes = new(StringComparer.OrdinalIgnoreCase)
    {
        "image/jpeg", "image/png", "image/webp"
    };

    private static readonly HashSet<string> VideoTypes = new(StringComparer.OrdinalIgnoreCase)
    {
        "video/mp4", "video/quicktime", "video/webm"
    };

    private readonly CloudinaryMediaService _mediaService;

    public MediaController(CloudinaryMediaService mediaService)
    {
        _mediaService = mediaService;
    }

    [HttpPost("upload")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(100 * 1024 * 1024)]
    public async Task<IActionResult> Upload([FromForm] UploadMediaRequest request, CancellationToken cancellationToken)
    {
        if (request.File == null || request.File.Length == 0)
        {
            return BadRequest(new { message = "Vui lòng chọn file ảnh hoặc video." });
        }

        var isImage = ImageTypes.Contains(request.File.ContentType);
        var isVideo = VideoTypes.Contains(request.File.ContentType);
        if (!isImage && !isVideo)
        {
            return BadRequest(new { message = "Chỉ hỗ trợ JPG, PNG, WEBP, MP4, MOV hoặc WEBM." });
        }

        var maxBytes = isImage ? 10L * 1024 * 1024 : 100L * 1024 * 1024;
        if (request.File.Length > maxBytes)
        {
            return BadRequest(new { message = isImage ? "Ảnh không được vượt quá 10MB." : "Video không được vượt quá 100MB." });
        }

        try
        {
            var result = await _mediaService.UploadAsync(
                request.File,
                isVideo ? "video" : "image",
                cancellationToken);

            return Ok(new
            {
                url = result.SecureUrl,
                publicId = result.PublicId,
                resourceType = result.ResourceType
            });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    public sealed class UploadMediaRequest
    {
        public IFormFile? File { get; set; }
    }
}
