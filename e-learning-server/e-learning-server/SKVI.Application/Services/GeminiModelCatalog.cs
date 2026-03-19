namespace SKVI.Application.Services
{
    internal static class GeminiModelCatalog
    {
        public const string DefaultModel = "gemini-2.5-flash";

        private static readonly HashSet<string> SupportedModels = new(StringComparer.OrdinalIgnoreCase)
        {
            "gemini-2.5-flash",
            "gemini-2.5-flash-lite",
            "gemini-2.5-pro"
        };

        private static readonly Dictionary<string, string> LegacyMappings = new(StringComparer.OrdinalIgnoreCase)
        {
            ["gemini-1.5-pro"] = DefaultModel,
            ["gemini-1.5-flash"] = DefaultModel,
            ["gemini-1.5-flash-8b"] = DefaultModel,
            ["gemini-2.0-flash"] = DefaultModel,
            ["gemini-2.0-flash-lite"] = DefaultModel,
            ["gemini-exp-1206"] = DefaultModel
        };

        public static string Normalize(string? modelName)
        {
            if (string.IsNullOrWhiteSpace(modelName))
            {
                return DefaultModel;
            }

            var trimmed = modelName.Trim();
            if (SupportedModels.Contains(trimmed))
            {
                return trimmed.ToLowerInvariant();
            }

            if (LegacyMappings.TryGetValue(trimmed, out var mappedModel))
            {
                return mappedModel;
            }

            return DefaultModel;
        }
    }
}
