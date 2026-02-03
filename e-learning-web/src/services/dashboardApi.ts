const API_URL = import.meta.env.VITE_API_URL || 'https://localhost:7145/api';

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

function getAuthHeaders(): HeadersInit {
    const authData = localStorage.getItem('auth');
    let token = '';
    if (authData) {
        try {
            const parsed = JSON.parse(authData);
            token = parsed.accessToken || '';
        } catch {
            // ignore
        }
    }
    return {
        'Content-Type': 'application/json',
        'Authorization': token ? `Bearer ${token}` : ''
    };
}

class DashboardApi {
    async getStats(): Promise<DashboardStats> {
        const response = await fetch(`${API_URL}/admin/dashboard/stats`, {
            method: 'GET',
            headers: getAuthHeaders(),
            credentials: 'include'
        });

        if (!response.ok) {
            let errorMessage = 'Failed to fetch dashboard stats';
            try {
                const error = await response.json();
                errorMessage = error.message || errorMessage;
            } catch {
                errorMessage = response.statusText || errorMessage;
            }
            throw new Error(errorMessage);
        }

        return response.json();
    }
}

export const dashboardApi = new DashboardApi();
