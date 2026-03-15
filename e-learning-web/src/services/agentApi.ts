import { apiClient } from './apiClient';

type ApiObject = Record<string, unknown>;

const isApiObject = (value: unknown): value is ApiObject =>
  typeof value === 'object' && value !== null && !Array.isArray(value);

const toString = (value: unknown, fallback = ''): string => {
  if (typeof value === 'string') {
    return value;
  }

  if (typeof value === 'number' || typeof value === 'boolean') {
    return String(value);
  }

  return fallback;
};

const toNumber = (value: unknown, fallback = 0): number => {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value;
  }

  if (typeof value === 'string') {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : fallback;
  }

  return fallback;
};

const toArray = (payload: unknown): unknown[] => {
  if (Array.isArray(payload)) {
    return payload;
  }

  if (!isApiObject(payload)) {
    return [];
  }

  const data = payload['data'];
  if (Array.isArray(data)) {
    return data;
  }

  const items = payload['items'];
  if (Array.isArray(items)) {
    return items;
  }

  return [];
};

const toPagedList = <T>(
  payload: unknown,
  mapper: (item: unknown, index: number) => T
): { data: T[]; total: number } => {
  const data = toArray(payload).map((item, index) => mapper(item, index));

  if (!isApiObject(payload)) {
    return { data, total: data.length };
  }

  const rawTotal = payload['total'] ?? payload['totalCount'] ?? payload['count'];
  return {
    data,
    total: toNumber(rawTotal, data.length),
  };
};

// DTOs from backend
export interface AgentDashboardStatsDto {
  totalSalesThisMonth: number;
  commissionPending: number;
  commissionReceived: number;
  totalActiveReferrals: number;
  totalStudentsFromReferral: number;
  salesGrowthPercentage: number;
  commissionGrowthPercentage: number;
  leaderboardRank: number;
}

export interface SalesDataDto {
  date: string;
  amount: number;
  count: number;
}

export interface ReferralDto {
  id: string;
  referralCode: string;
  referrerName: string;
  studentId: string;
  studentName: string;
  studentEmail: string;
  enrolledCourseId: string;
  enrolledCourseName: string;
  status: 'PENDING' | 'APPROVED' | 'REJECTED' | 'PAID';
  commissionAmount: number;
  createdAt: string;
  approvedAt?: string;
}

export interface CommissionBreakdownDto {
  totalCommission: number;
  paidCommission: number;
  pendingCommission: number;
  monthlyAverage: number;
  payoutHistory: CommissionHistoryDto[];
}

export interface CommissionHistoryDto {
  id: string;
  amount: number;
  status: 'PENDING' | 'PAID' | 'PROCESSING';
  fromDate: string;
  toDate: string;
  payoutDate?: string;
}

export interface AgentStudentDto {
  id: string;
  fullName: string;
  email: string;
  enrolledAt: string;
  status: 'ACTIVE' | 'INACTIVE' | 'COMPLETED';
  courseCount: number;
  totalSpent: number;
}

export interface LeaderboardEntryDto {
  rank: number;
  agentId: string;
  agentName: string;
  totalSales: number;
  studentCount: number;
  commissionEarned: number;
}

export interface AgentReportDto {
  period: string;
  totalSales: number;
  totalStudents: number;
  activeReferrals: number;
  conversionRate: number;
  averageOrderValue: number;
  topPerformingCourse: string;
  topPerformingCourseRevenue: number;
}

export interface GenerateReferralLinkRequestDto {
  courseId: string;
  expiryDays?: number;
}

export interface ReferralLinkResponseDto {
  referralCode: string;
  referralUrl: string;
  expiryDate: string;
}

const normalizeReferralStatus = (
  value: unknown
): ReferralDto['status'] => {
  const status = toString(value, 'PENDING').toUpperCase();

  if (status === 'APPROVED' || status === 'PAID' || status === 'REJECTED') {
    return status;
  }

  return 'PENDING';
};

const normalizePayoutStatus = (
  value: unknown
): CommissionHistoryDto['status'] => {
  const status = toString(value, 'PENDING').toUpperCase();

  if (status === 'PAID' || status === 'PENDING' || status === 'PROCESSING') {
    return status;
  }

  if (status === 'EARNED' || status === 'APPROVED') {
    return 'PROCESSING';
  }

  return 'PENDING';
};

const normalizeStudentStatus = (
  value: unknown
): AgentStudentDto['status'] => {
  const status = toString(value, 'ACTIVE').toUpperCase();

  if (status === 'ACTIVE' || status === 'INACTIVE' || status === 'COMPLETED') {
    return status;
  }

  return 'ACTIVE';
};

const mapSalesData = (payload: unknown, index: number): SalesDataDto => {
  const source = isApiObject(payload) ? payload : {};

  return {
    date: toString(source['date'], toString(source['week'], `Point ${index + 1}`)),
    amount: toNumber(source['amount']),
    count: toNumber(source['count'], toNumber(source['coursesSold'])),
  };
};

const mapReferral = (payload: unknown, index: number): ReferralDto => {
  const source = isApiObject(payload) ? payload : {};
  const referrerName = toString(source['referrerName'], 'Agent');

  return {
    id: toString(source['id'], `ref-${index + 1}`),
    referralCode: toString(source['referralCode'], toString(source['id'], `REF-${index + 1}`)),
    referrerName,
    studentId: toString(source['studentId']),
    studentName: toString(
      source['studentName'],
      toString(source['customerName'], 'Unknown')
    ),
    studentEmail: toString(source['studentEmail'], toString(source['customerEmail'])),
    enrolledCourseId: toString(source['enrolledCourseId']),
    enrolledCourseName: toString(source['enrolledCourseName'], toString(source['courseName'], '-')),
    status: normalizeReferralStatus(source['status']),
    commissionAmount: toNumber(source['commissionAmount']),
    createdAt: toString(source['createdAt'], new Date().toISOString()),
    approvedAt: source['approvedAt'] ? toString(source['approvedAt']) : undefined,
  };
};

const mapCommissionHistory = (
  payload: unknown,
  index: number
): CommissionHistoryDto => {
  const source = isApiObject(payload) ? payload : {};
  const date = toString(source['date'], new Date().toISOString());
  const payoutDate = source['payoutDate'] ?? source['paidAt'] ?? source['date'];

  return {
    id: toString(source['id'], `history-${index + 1}`),
    amount: toNumber(source['amount']),
    status: normalizePayoutStatus(source['status']),
    fromDate: toString(source['fromDate'], date),
    toDate: toString(source['toDate'], date),
    payoutDate: payoutDate ? toString(payoutDate) : undefined,
  };
};

const mapCommissionBreakdown = (payload: unknown): CommissionBreakdownDto => {
  const source = isApiObject(payload) ? payload : {};

  if (
    source['totalCommission'] !== undefined ||
    source['paidCommission'] !== undefined ||
    source['pendingCommission'] !== undefined ||
    source['monthlyAverage'] !== undefined
  ) {
    return {
      totalCommission: toNumber(source['totalCommission']),
      paidCommission: toNumber(source['paidCommission']),
      pendingCommission: toNumber(source['pendingCommission']),
      monthlyAverage: toNumber(source['monthlyAverage']),
      payoutHistory: toArray(source['payoutHistory']).map(mapCommissionHistory),
    };
  }

  const paidCommission = toNumber(source['totalPaidLifetime']);
  const pendingCommission = toNumber(source['pendingPayment']);

  return {
    totalCommission: paidCommission + pendingCommission,
    paidCommission,
    pendingCommission,
    monthlyAverage: toNumber(source['earningThisMonth']),
    payoutHistory: toArray(source['history']).map(mapCommissionHistory),
  };
};

const mapStudent = (payload: unknown, index: number): AgentStudentDto => {
  const source = isApiObject(payload) ? payload : {};

  return {
    id: toString(source['id'], `student-${index + 1}`),
    fullName: toString(source['fullName'], 'N/A'),
    email: toString(source['email']),
    enrolledAt: toString(source['enrolledAt'], toString(source['enrolledDate'], new Date().toISOString())),
    status: normalizeStudentStatus(source['status']),
    courseCount: toNumber(source['courseCount'], toNumber(source['totalCoursesEnrolled'])),
    totalSpent: toNumber(source['totalSpent']),
  };
};

const mapLeaderboardEntry = (
  payload: unknown,
  index: number
): LeaderboardEntryDto => {
  const source = isApiObject(payload) ? payload : {};
  const rank = toNumber(source['rank'], index + 1);
  const agentName = toString(source['agentName'], `Agent #${rank}`);

  return {
    rank,
    agentId: toString(source['agentId'], `${rank}-${agentName}`),
    agentName,
    totalSales: toNumber(source['totalSales']),
    studentCount: toNumber(source['studentCount'], toNumber(source['studentsEnrolled'])),
    commissionEarned: toNumber(source['commissionEarned'], toNumber(source['commission'])),
  };
};

const mapStats = (payload: unknown): AgentDashboardStatsDto => {
  const source = isApiObject(payload) ? payload : {};

  return {
    totalSalesThisMonth: toNumber(source['totalSalesThisMonth'], toNumber(source['TotalSalesThisMonth'])),
    commissionPending: toNumber(source['commissionPending'], toNumber(source['CommissionPending'])),
    commissionReceived: toNumber(source['commissionReceived'], toNumber(source['CommissionReceived'])),
    totalActiveReferrals: toNumber(source['totalActiveReferrals'], toNumber(source['TotalActiveReferrals'])),
    totalStudentsFromReferral: toNumber(source['totalStudentsFromReferral'], toNumber(source['TotalStudentsFromReferral'])),
    salesGrowthPercentage: toNumber(source['salesGrowthPercentage'], toNumber(source['SalesGrowthPercentage'])),
    commissionGrowthPercentage: toNumber(source['commissionGrowthPercentage'], toNumber(source['CommissionGrowthPercentage'])),
    leaderboardRank: toNumber(source['leaderboardRank'], toNumber(source['LeaderboardRank'], 1)),
  };
};

const mapReport = (payload: unknown): AgentReportDto => {
  const source = isApiObject(payload) ? payload : {};

  return {
    period: toString(source['period'], toString(source['month'])),
    totalSales: toNumber(source['totalSales']),
    totalStudents: toNumber(source['totalStudents'], toNumber(source['referralsCount'])),
    activeReferrals: toNumber(source['activeReferrals'], toNumber(source['referralsCount'])),
    conversionRate: toNumber(source['conversionRate']),
    averageOrderValue: toNumber(source['averageOrderValue']),
    topPerformingCourse: toString(source['topPerformingCourse'], '-'),
    topPerformingCourseRevenue: toNumber(source['topPerformingCourseRevenue']),
  };
};

const mapReferralLink = (payload: unknown): ReferralLinkResponseDto => {
  const source = isApiObject(payload) ? payload : {};

  return {
    referralCode: toString(source['referralCode'], toString(source['code'])),
    referralUrl: toString(source['referralUrl'], toString(source['link'])),
    expiryDate: toString(source['expiryDate'], toString(source['createdAt'])),
  };
};

export const agentApi = {
  async getStats(): Promise<AgentDashboardStatsDto> {
    const response = await apiClient('/agent/dashboard/stats', { method: 'GET' });
    return mapStats(response);
  },

  async getSalesChart(month?: number): Promise<SalesDataDto[]> {
    const params = month ? `?month=${month}` : '';
    const response = await apiClient(`/agent/dashboard/sales-chart${params}`, { method: 'GET' });
    return toArray(response).map(mapSalesData);
  },

  async getReferrals(
    page: number = 1,
    pageSize: number = 20,
    status?: string
  ): Promise<{ data: ReferralDto[]; total: number }> {
    const params = new URLSearchParams({
      page: page.toString(),
      pageSize: pageSize.toString(),
    });
    if (status) params.append('status', status);

    const response = await apiClient(`/agent/dashboard/referrals?${params}`, { method: 'GET' });
    return toPagedList(response, mapReferral);
  },

  async getCommission(): Promise<CommissionBreakdownDto> {
    const response = await apiClient('/agent/dashboard/commission', { method: 'GET' });
    return mapCommissionBreakdown(response);
  },

  async getStudents(
    page: number = 1,
    pageSize: number = 20
  ): Promise<{ data: AgentStudentDto[]; total: number }> {
    const params = new URLSearchParams({
      page: page.toString(),
      pageSize: pageSize.toString(),
    });

    const response = await apiClient(`/agent/dashboard/students?${params}`, { method: 'GET' });
    return toPagedList(response, mapStudent);
  },

  async getLeaderboard(): Promise<LeaderboardEntryDto[]> {
    const response = await apiClient('/agent/dashboard/leaderboard', { method: 'GET' });
    return toArray(response).map(mapLeaderboardEntry);
  },

  async generateReferralLink(
    data: GenerateReferralLinkRequestDto
  ): Promise<ReferralLinkResponseDto> {
    const response = await apiClient('/agent/dashboard/referral-link', {
      method: 'POST',
      body: JSON.stringify(data),
    });

    return mapReferralLink(response);
  },

  async getReport(year: number, month: number): Promise<AgentReportDto> {
    const response = await apiClient(
      `/agent/dashboard/report?year=${year}&month=${month}`,
      { method: 'GET' }
    );

    return mapReport(response);
  },
};
