import { apiClient } from './apiClient';




export interface SignedVideoUrlResponse {
  streamUrl: string;
  expiresIn: number; // seconds
}

export interface EmbedUrlResponse {
  embedUrl: string;
}

class VideoApi {


  async getStreamUrl(videoId: string): Promise<SignedVideoUrlResponse> {
    return apiClient(`/videos/${videoId}/stream-url`);
  }

  async getEmbedUrl(videoId: string): Promise<EmbedUrlResponse> {
    return apiClient(`/videos/${videoId}/embed-url`);
  }
}

export const videoApi = new VideoApi();
