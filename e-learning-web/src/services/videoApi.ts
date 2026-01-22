const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://localhost:7145/api';

export interface SignedVideoUrlResponse {
  streamUrl: string;
  expiresIn: number; // seconds
}

export interface EmbedUrlResponse {
  embedUrl: string;
}

class VideoApi {
  private getAuthHeaders(): HeadersInit {
    const token = localStorage.getItem('accessToken');
    return {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    };
  }

  async getStreamUrl(videoId: string): Promise<SignedVideoUrlResponse> {
    const response = await fetch(`${API_BASE_URL}/videos/${videoId}/stream-url`, {
      method: 'GET',
      headers: this.getAuthHeaders(),
      credentials: 'include',
    });

    if (!response.ok) {
      throw new Error('Failed to get stream URL');
    }

    return response.json();
  }

  async getEmbedUrl(videoId: string): Promise<EmbedUrlResponse> {
    const response = await fetch(`${API_BASE_URL}/videos/${videoId}/embed-url`, {
      method: 'GET',
      headers: this.getAuthHeaders(),
      credentials: 'include',
    });

    if (!response.ok) {
      throw new Error('Failed to get embed URL');
    }

    return response.json();
  }
}

export const videoApi = new VideoApi();
