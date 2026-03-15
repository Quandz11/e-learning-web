import { apiClient } from './apiClient';

export interface CheckoutRequest {
  courseIds: string[];
  referralCode?: string;
}

export interface ReferralPreviewResponse {
  referralCode: string;
  cabinId: string;
  cabinName: string;
  ownerUserId: string;
  ownerName: string;
}

export interface CheckoutItemDto {
  courseId: string;
  title: string;
  price: number;
  isFree: boolean;
}

export interface PaymentInstructionDto {
  bankBin?: string;
  bankName?: string;
  bankShortName?: string;
  accountNumber?: string;
  accountName?: string;
  transferContent?: string;
  amount: number;
}

export interface CheckoutResponse {
  orderId: string;
  payOSOrderCode?: number;
  totalAmount: number;
  status: string;
  requiresPayment: boolean;
  checkoutUrl?: string;
  qrCode?: string;
  paymentLinkId?: string;
  paymentInstruction?: PaymentInstructionDto;
  createdAt: string;
  expiresAt?: string;
  items: CheckoutItemDto[];
}

export interface UserOrderSummaryDto {
  orderId: string;
  payOSOrderCode?: number;
  totalAmount: number;
  status: string;
  lastPaymentStatus?: string;
  createdAt: string;
  paidAt?: string;
  items: CheckoutItemDto[];
}

export interface OrderStatusResponse {
  orderId: string;
  payOSOrderCode?: number;
  totalAmount: number;
  status: string;
  lastPaymentStatus?: string;
  isPaid: boolean;
  createdAt: string;
  paidAt?: string;
  paymentLinkId?: string;
  checkoutUrl?: string;
  qrCode?: string;
  paymentInstruction?: PaymentInstructionDto;
  items: CheckoutItemDto[];
}

export const paymentApi = {
  async previewReferralCode(code: string): Promise<ReferralPreviewResponse> {
    return apiClient(`/payments/referrals/preview?code=${encodeURIComponent(code)}`);
  },

  async createCheckout(payload: CheckoutRequest): Promise<CheckoutResponse> {
    return apiClient('/payments/checkout', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  async getMyOrders(): Promise<UserOrderSummaryDto[]> {
    return apiClient('/payments/orders');
  },

  async getOrderStatus(orderId: string, refresh = true): Promise<OrderStatusResponse> {
    return apiClient(`/payments/orders/${orderId}?refresh=${refresh}`);
  },

  async getOrderStatusByCode(orderCode: number, refresh = true): Promise<OrderStatusResponse> {
    return apiClient(`/payments/orders/by-code/${orderCode}?refresh=${refresh}`);
  },

  async confirmWebhook(): Promise<{ message: string }> {
    return apiClient('/payments/webhook/payos/confirm', {
      method: 'POST',
    });
  },
};
