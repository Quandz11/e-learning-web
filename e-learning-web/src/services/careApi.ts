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
export interface CareDashboardStatsDto {
  totalCustomers: number;
  activeTickets: number;
  averageSatisfaction: number;
  unresolvedTickets: number;
  satisfactionTrend: number;
}

export interface SupportTicketDto {
  id: string;
  title: string;
  description: string;
  status: 'OPEN' | 'IN_PROGRESS' | 'RESOLVED' | 'CLOSED';
  priority: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
  customerId: string;
  customerName: string;
  customerEmail: string;
  createdAt: string;
  updatedAt: string;
  resolvedAt?: string;
  assignedTo?: string;
}

export interface CareCustomerDto {
  id: string;
  fullName: string;
  email: string;
  phone?: string;
  avatarUrl?: string;
  enrolledCourses: number;
  supportTickets: number;
  joinedDate: string;
}

export interface CareChatMessageDto {
  id: string;
  senderId: string;
  senderName: string;
  senderAvatar?: string;
  message: string;
  timestamp: string;
  isRead: boolean;
}

export interface SatisfactionFeedbackDto {
  id: string;
  customerId: string;
  customerName: string;
  rating: number;
  feedback: string;
  createdAt: string;
}

export interface CreateSupportTicketDto {
  title: string;
  description: string;
  priority: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
}

export interface UpdateSupportTicketDto {
  status: 'OPEN' | 'IN_PROGRESS' | 'RESOLVED' | 'CLOSED';
  assignedTo?: string;
}

const normalizeTicketStatus = (value: unknown): SupportTicketDto['status'] => {
  const normalized = toString(value, 'OPEN')
    .toUpperCase()
    .replace(/\s+/g, '_');

  if (normalized === 'INPROGRESS') {
    return 'IN_PROGRESS';
  }

  if (normalized === 'RESOLVED' || normalized === 'CLOSED' || normalized === 'IN_PROGRESS') {
    return normalized;
  }

  return 'OPEN';
};

const normalizeTicketPriority = (value: unknown): SupportTicketDto['priority'] => {
  const normalized = toString(value, 'MEDIUM').toUpperCase();

  if (normalized === 'LOW' || normalized === 'MEDIUM' || normalized === 'HIGH') {
    return normalized;
  }

  if (normalized === 'URGENT') {
    return 'CRITICAL';
  }

  return 'CRITICAL';
};

const mapStats = (payload: unknown): CareDashboardStatsDto => {
  const source = isApiObject(payload) ? payload : {};
  const pendingTickets = toNumber(source['pendingTickets'], toNumber(source['PendingTickets']));

  return {
    totalCustomers: toNumber(source['totalCustomers'], toNumber(source['TotalCustomersThisMonth'])),
    activeTickets: toNumber(source['activeTickets'], pendingTickets),
    averageSatisfaction: toNumber(source['averageSatisfaction'], toNumber(source['AverageSatisfactionScore'])),
    unresolvedTickets: toNumber(source['unresolvedTickets'], pendingTickets),
    satisfactionTrend: toNumber(source['satisfactionTrend'], toNumber(source['SatisfactionTrendPercentage'])),
  };
};

const mapTicket = (payload: unknown, index = 0): SupportTicketDto => {
  const source = isApiObject(payload) ? payload : {};

  return {
    id: toString(source['id'], toString(source['Id'], `ticket-${index + 1}`)),
    title: toString(source['title'], toString(source['Title'], '-')),
    description: toString(source['description'], toString(source['Description'])),
    status: normalizeTicketStatus(source['status'] ?? source['Status']),
    priority: normalizeTicketPriority(source['priority'] ?? source['Priority']),
    customerId: toString(source['customerId']),
    customerName: toString(source['customerName'], toString(source['CustomerName'], 'Unknown')),
    customerEmail: toString(source['customerEmail'], toString(source['CustomerEmail'])),
    createdAt: toString(source['createdAt'], toString(source['CreatedAt'], new Date().toISOString())),
    updatedAt: toString(source['updatedAt'], toString(source['UpdatedAt'], new Date().toISOString())),
    resolvedAt: source['resolvedAt'] ? toString(source['resolvedAt']) : undefined,
    assignedTo: source['assignedTo'] ? toString(source['assignedTo']) : undefined,
  };
};

const mapCustomer = (payload: unknown, index = 0): CareCustomerDto => {
  const source = isApiObject(payload) ? payload : {};
  const email = toString(source['email'], toString(source['Email']));
  const fullName = toString(source['fullName'], toString(source['FullName'], email || `User ${index + 1}`));

  return {
    id: toString(source['id'], toString(source['Id'], `customer-${index + 1}`)),
    fullName,
    email,
    phone: toString(source['phone'], toString(source['Phone'])) || undefined,
    avatarUrl: toString(source['avatarUrl']) || undefined,
    enrolledCourses: toNumber(source['enrolledCourses']),
    supportTickets: toNumber(source['supportTickets'], toNumber(source['totalTickets'], toNumber(source['TotalTickets']))),
    joinedDate: toString(source['joinedDate'], toString(source['createdAt'], toString(source['CreatedAt'], new Date().toISOString()))),
  };
};

const mapSatisfactionFeedback = (payload: unknown, index = 0): SatisfactionFeedbackDto => {
  const source = isApiObject(payload) ? payload : {};

  return {
    id: toString(source['id'], `feedback-${index + 1}`),
    customerId: toString(source['customerId']),
    customerName: toString(source['customerName']),
    rating: toNumber(source['rating'], toNumber(source['averageScore'], toNumber(source['AverageScore']))),
    feedback: toString(source['feedback']),
    createdAt: toString(source['createdAt'], toString(source['date'], toString(source['Date'], new Date().toISOString()))),
  };
};

const mapMessage = (payload: unknown, index = 0): CareChatMessageDto => {
  const source = isApiObject(payload) ? payload : {};

  return {
    id: toString(source['id'], toString(source['Id'], `message-${index + 1}`)),
    senderId: toString(source['senderId'], toString(source['ticketId'], toString(source['TicketId']))),
    senderName: toString(source['senderName'], toString(source['customerName'], toString(source['CustomerName'], 'Customer'))),
    senderAvatar: toString(source['senderAvatar']) || undefined,
    message: toString(source['message'], toString(source['Message'])),
    timestamp: toString(source['timestamp'], toString(source['createdAt'], toString(source['CreatedAt'], new Date().toISOString()))),
    isRead: Boolean(source['isRead'] ?? source['IsRead']),
  };
};

export const careApi = {
  async getStats(): Promise<CareDashboardStatsDto> {
    const response = await apiClient('/care/dashboard/stats', { method: 'GET' });
    return mapStats(response);
  },

  async getSupportTickets(
    page: number = 1,
    pageSize: number = 10,
    status?: string,
    search?: string
  ): Promise<{ data: SupportTicketDto[]; total: number }> {
    const params = new URLSearchParams({
      page: page.toString(),
      pageSize: pageSize.toString(),
    });
    if (status) params.append('status', status);
    if (search) params.append('search', search);

    const response = await apiClient(`/care/dashboard/support-tickets?${params}`, { method: 'GET' });
    return toPagedList(response, mapTicket);
  },

  async getSupportTicket(ticketId: string): Promise<SupportTicketDto> {
    const response = await apiClient(`/care/dashboard/support-tickets/${ticketId}`, { method: 'GET' });
    return mapTicket(response);
  },

  async createSupportTicket(data: CreateSupportTicketDto): Promise<SupportTicketDto> {
    const response = await apiClient('/care/dashboard/support-tickets', {
      method: 'POST',
      body: JSON.stringify(data),
    });

    return mapTicket(response);
  },

  async updateSupportTicket(
    ticketId: string,
    data: UpdateSupportTicketDto
  ): Promise<SupportTicketDto> {
    const response = await apiClient(`/care/dashboard/support-tickets/${ticketId}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    });

    return mapTicket(response);
  },

  async getCustomers(
    page: number = 1,
    pageSize: number = 20,
    search?: string
  ): Promise<{ data: CareCustomerDto[]; total: number }> {
    const params = new URLSearchParams({
      page: page.toString(),
      pageSize: pageSize.toString(),
    });
    if (search) params.append('search', search);

    const response = await apiClient(`/care/dashboard/customers?${params}`, { method: 'GET' });
    return toPagedList(response, mapCustomer);
  },

  async getSatisfactionTrend(days: number = 30): Promise<SatisfactionFeedbackDto[]> {
    const response = await apiClient(`/care/dashboard/satisfaction-trend?days=${days}`, { method: 'GET' });
    return toArray(response).map(mapSatisfactionFeedback);
  },

  async getMessages(): Promise<CareChatMessageDto[]> {
    const response = await apiClient('/care/dashboard/messages', { method: 'GET' });
    return toArray(response).map(mapMessage);
  },
};
