import { apiClient } from './apiClient';


export interface DocumentUploadResponse {
    documentId: string;
    fileUrl: string;
}

export interface DocumentResponse {
    id: string;
    fileName: string;
    fileUrl: string;
    fileSizeBytes: number;
    uploadedAt: string;
}



export const documentApi = {
    async uploadPdf(file: File): Promise<DocumentUploadResponse> {
        const formData = new FormData();
        formData.append('file', file);

        try {
            return apiClient('/documents/upload', {
                method: 'POST',
                body: formData,
            });
        } catch {
            throw new Error('Failed to upload PDF');
        }
    },

    async getById(id: string): Promise<DocumentResponse> {
        return apiClient(`/documents/${id}`);
    },
};
