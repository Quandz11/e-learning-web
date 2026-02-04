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



class DashboardApi {
    async getStats(): Promise<DashboardStats> {
        return apiClient('/admin/dashboard/stats');
    }
}

export const dashboardApi = new DashboardApi();
