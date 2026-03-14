import type { CourseResponse } from './courseApi';

const PAYMENT_CART_KEY = 'elearning_payment_cart_v1';
export const PAYMENT_CART_CHANGED_EVENT = 'payment-cart-changed';

export interface PaymentCartItem {
  courseId: string;
  title: string;
  price: number;
  isFree: boolean;
  thumbnailUrl?: string;
}

const emitCartChanged = () => {
  if (typeof window !== 'undefined') {
    window.dispatchEvent(new CustomEvent(PAYMENT_CART_CHANGED_EVENT));
  }
};

const parseCart = (raw: string | null): PaymentCartItem[] => {
  if (!raw) {
    return [];
  }

  try {
    const parsed = JSON.parse(raw) as unknown;
    if (!Array.isArray(parsed)) {
      return [];
    }

    return parsed
      .filter((item) => item && typeof item === 'object')
      .map((item) => {
        const data = item as Record<string, unknown>;
        return {
          courseId: String(data.courseId ?? ''),
          title: String(data.title ?? ''),
          price: Number(data.price ?? 0),
          isFree: Boolean(data.isFree),
          thumbnailUrl: data.thumbnailUrl ? String(data.thumbnailUrl) : undefined,
        };
      })
      .filter((item) => item.courseId);
  } catch {
    return [];
  }
};

const saveCart = (items: PaymentCartItem[]) => {
  localStorage.setItem(PAYMENT_CART_KEY, JSON.stringify(items));
  emitCartChanged();
};

export const paymentCart = {
  getItems(): PaymentCartItem[] {
    if (typeof window === 'undefined') {
      return [];
    }

    return parseCart(localStorage.getItem(PAYMENT_CART_KEY));
  },

  setItems(items: PaymentCartItem[]): void {
    saveCart(items);
  },

  clear(): void {
    if (typeof window === 'undefined') {
      return;
    }

    localStorage.removeItem(PAYMENT_CART_KEY);
    emitCartChanged();
  },

  count(): number {
    return this.getItems().length;
  },

  hasCourse(courseId: string): boolean {
    return this.getItems().some((item) => item.courseId === courseId);
  },

  addCourse(course: CourseResponse): void {
    const items = this.getItems();
    if (items.some((item) => item.courseId === course.id)) {
      return;
    }

    items.push({
      courseId: course.id,
      title: course.title,
      price: course.price,
      isFree: course.isFree,
      thumbnailUrl: course.thumbnailUrl,
    });

    saveCart(items);
  },

  removeCourse(courseId: string): void {
    const items = this.getItems().filter((item) => item.courseId !== courseId);
    saveCart(items);
  },

  removeMany(courseIds: string[]): void {
    if (courseIds.length === 0) {
      return;
    }

    const idSet = new Set(courseIds);
    const items = this.getItems().filter((item) => !idSet.has(item.courseId));
    saveCart(items);
  },
};
