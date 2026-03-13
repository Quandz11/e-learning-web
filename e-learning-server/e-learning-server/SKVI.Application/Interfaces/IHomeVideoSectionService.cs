using SKVI.Application.DTOs.Home;

namespace SKVI.Application.Interfaces;

public interface IHomeVideoSectionService
{
    Task<HomeVideoSectionDto?> GetHomeVideoSectionAsync();
    Task<HomeVideoSectionDto> UpdateHomeVideoSectionAsync(UpdateHomeVideoSectionDto dto);
}
