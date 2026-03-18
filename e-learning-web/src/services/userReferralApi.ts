import { apiClient } from './apiClient';

export interface UserReferralDto {
    id: string;
    userId: string;
    referralCode: string;
    discountCode: string;
    discountPercent: number;
    isActive: boolean;
    createdAt: string;
    updatedAt: string;
}

export interface UserReferralStatsDto {
    totalInvites: number;
    successfulInvites: number;
    pendingInvites: number;
}

export interface UserReferralOverviewDto {
    referral: UserReferralDto;
    stats: UserReferralStatsDto;
}

export interface PagedResult<T> {
    items: T[];
    total: number;
    page: number;
    pageSize: number;
}

export interface AdminUserReferralItemDto {
    id: string;
    userId: string;
    userName?: string;
    userEmail: string;
    referralCode: string;
    discountCode: string;
    discountPercent: number;
    isActive: boolean;
    totalInvites: number;
    successfulInvites: number;
    pendingInvites: number;
    referredPaidOrderCount: number;
    referredPaidRevenue: number;
    createdAt: string;
    updatedAt: string;
}

export interface AdminUpdateUserReferralRequest {
    discountCode: string;
    discountPercent: number;
    isActive: boolean;
}

export interface AdminBulkUpdateDiscountPercentRequest {
    referralIds: string[];
    discountPercent: number;
}

export interface AdminBulkUpdateDiscountPercentResultDto {
    requestedCount: number;
    updatedCount: number;
    discountPercent: number;
    updatedAt: string;
}

export const userReferralApi = {
    async getMyReferral(): Promise<UserReferralOverviewDto> {
        return apiClient('/user/referral/my-referral');
    },

    async generateMyReferral(): Promise<UserReferralOverviewDto> {
        return apiClient('/user/referral/generate', {
            method: 'POST',
        });
    },

    async getAdminPaged(params: {
        search?: string;
        isActive?: boolean;
        page?: number;
        pageSize?: number;
    }): Promise<PagedResult<AdminUserReferralItemDto>> {
        const searchParams = new URLSearchParams();

        if (params.search) {
            searchParams.set('search', params.search);
        }

        if (typeof params.isActive === 'boolean') {
            searchParams.set('isActive', String(params.isActive));
        }

        searchParams.set('page', String(params.page ?? 1));
        searchParams.set('pageSize', String(params.pageSize ?? 20));

        return apiClient(`/admin/user-referrals?${searchParams.toString()}`);
    },

    async updateByAdmin(id: string, payload: AdminUpdateUserReferralRequest): Promise<AdminUserReferralItemDto> {
        return apiClient(`/admin/user-referrals/${id}`, {
            method: 'PUT',
            body: JSON.stringify(payload),
        });
    },

    async bulkUpdateDiscountPercentByAdmin(
        payload: AdminBulkUpdateDiscountPercentRequest
    ): Promise<AdminBulkUpdateDiscountPercentResultDto> {
        return apiClient('/admin/user-referrals/bulk-discount-percent', {
            method: 'POST',
            body: JSON.stringify(payload),
        });
    },

    async regenerateDiscountCode(id: string): Promise<AdminUserReferralItemDto> {
        return apiClient(`/admin/user-referrals/${id}/regenerate-discount`, {
            method: 'POST',
        });
    },
};
