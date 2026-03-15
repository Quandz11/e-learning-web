import { apiClient } from './apiClient';

export type LeadStatus = 'NEW' | 'CONTACTED' | 'CONSULTING' | 'CONVERTED' | 'LOST';

export interface LeadRegistrationDto {
  id: string;
  fullName: string;
  email: string;
  phone: string;
  goal: string;
  status: LeadStatus;
  source: string;
  assignedCareId?: string;
  assignedCareName?: string;
  createdAt: string;
  updatedAt: string;
}

export interface LeadRegistrationPagedResultDto {
  items: LeadRegistrationDto[];
  total: number;
  page: number;
  pageSize: number;
}

export interface CreateLeadRegistrationRequest {
  fullName: string;
  email: string;
  phone: string;
  goal: string;
}

export interface UpdateLeadRegistrationRequest {
  fullName?: string;
  email?: string;
  phone?: string;
  goal?: string;
  status?: LeadStatus;
  assignedCareId?: string;
}

export const leadApi = {
  async createPublic(payload: CreateLeadRegistrationRequest): Promise<LeadRegistrationDto> {
    return apiClient('/lead-registrations', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  async getPaged(params: {
    search?: string;
    status?: LeadStatus;
    page?: number;
    pageSize?: number;
  }): Promise<LeadRegistrationPagedResultDto> {
    const searchParams = new URLSearchParams();

    if (params.search) {
      searchParams.set('search', params.search);
    }

    if (params.status) {
      searchParams.set('status', params.status);
    }

    searchParams.set('page', String(params.page ?? 1));
    searchParams.set('pageSize', String(params.pageSize ?? 20));

    return apiClient(`/lead-registrations?${searchParams.toString()}`);
  },

  async getById(id: string): Promise<LeadRegistrationDto> {
    return apiClient(`/lead-registrations/${id}`);
  },

  async update(id: string, payload: UpdateLeadRegistrationRequest): Promise<LeadRegistrationDto> {
    return apiClient(`/lead-registrations/${id}`, {
      method: 'PUT',
      body: JSON.stringify(payload),
    });
  },

  async remove(id: string): Promise<void> {
    return apiClient(`/lead-registrations/${id}`, {
      method: 'DELETE',
    });
  },
};
