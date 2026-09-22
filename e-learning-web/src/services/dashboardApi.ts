import { apiClient } from './apiClient';


export interface DashboardStats {
    totalStudents: number;
    totalRevenue: number;
    agentRevenue: number;
    activeCourses: number;
    studentGrowthPercentage: number;
    revenueGrowthPercentage: number;
    agentRevenueGrowthPercentage: number;
    coursesGrowthPercentage: number;
}

export interface RecentOrder {
    id: string;
    student: string;
    avatarUrl?: string;
    initials?: string;
    course: string;
    amount: number;
    formattedAmount: string;
    status: 'paid' | 'pending' | 'failed';
    date: string;
    formattedDate: string;
}

export interface TopAgent {
    id: string;
    name: string;
    avatarUrl?: string;
    revenue: number;
    formattedRevenue: string;
    orderCount: number;
    rank: number;
    percentage: number;
}

class DashboardApi {
    async getStats(): Promise<DashboardStats> {
        return apiClient('/admin/dashboard/stats');
    }

    async getRecentOrders(limit = 10): Promise<RecentOrder[]> {
        return apiClient(`/admin/dashboard/recent-orders?limit=${limit}`);
    }

    async getTopAgents(limit = 5): Promise<TopAgent[]> {
        return apiClient(`/admin/dashboard/top-agents?limit=${limit}`);
    }
}

export const dashboardApi = new DashboardApi();
