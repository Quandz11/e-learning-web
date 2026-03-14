import { apiClient } from './apiClient';

export interface ReferralItemDto {
  id: string;
  name: string;
  referralCode: string;
  ownerUserId: string;
  ownerName?: string;
  ownerEmail: string;
  commissionRate: number;
  walletBalance: number;
  isActive: boolean;
  createdAt: string;
}

export interface ReferralPagedResultDto {
  items: ReferralItemDto[];
  total: number;
  page: number;
  pageSize: number;
}

export interface CreateReferralRequest {
  name: string;
  ownerUserId: string;
  referralCode: string;
  commissionRate: number;
  isActive?: boolean;
}

export interface UpdateReferralRequest {
  name: string;
  ownerUserId: string;
  referralCode: string;
  commissionRate: number;
  isActive: boolean;
}

export const referralApi = {
  async getPaged(params: { search?: string; isActive?: boolean; page?: number; pageSize?: number }): Promise<ReferralPagedResultDto> {
    const searchParams = new URLSearchParams();

    if (params.search) {
      searchParams.set('search', params.search);
    }

    if (typeof params.isActive === 'boolean') {
      searchParams.set('isActive', String(params.isActive));
    }

    searchParams.set('page', String(params.page ?? 1));
    searchParams.set('pageSize', String(params.pageSize ?? 20));

    return apiClient(`/admin/referrals?${searchParams.toString()}`);
  },

  async getById(id: string): Promise<ReferralItemDto> {
    return apiClient(`/admin/referrals/${id}`);
  },

  async create(payload: CreateReferralRequest): Promise<ReferralItemDto> {
    return apiClient('/admin/referrals', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  async update(id: string, payload: UpdateReferralRequest): Promise<ReferralItemDto> {
    return apiClient(`/admin/referrals/${id}`, {
      method: 'PUT',
      body: JSON.stringify(payload),
    });
  },

  async remove(id: string): Promise<void> {
    return apiClient(`/admin/referrals/${id}`, {
      method: 'DELETE',
    });
  },
};
