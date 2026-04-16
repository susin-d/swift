// ---- Types ----
export type UserStatus = "active" | "blocked" | "pending_deletion";
export type VendorStatus = "pending" | "approved" | "rejected" | "suspended";
export type OrderStatus = "placed" | "preparing" | "out_for_delivery" | "delivered" | "cancelled" | "refunded";
export type PayoutStatus = "pending" | "completed" | "failed";
export type TicketStatus = "open" | "in_progress" | "resolved" | "closed";

export interface MockUser {
  id: string;
  name: string;
  email: string;
  phone: string;
  status: UserStatus;
  joinedAt: string;
  totalOrders: number;
  totalSpent: number;
}

export interface MockVendor {
  id: string;
  name: string;
  ownerName: string;
  email: string;
  status: VendorStatus;
  rating: number;
  totalOrders: number;
  revenue: number;
  joinedAt: string;
  cuisine: string;
  payoutStatus: PayoutStatus;
  pendingPayout: number;
}

export interface OrderItem {
  name: string;
  qty: number;
  price: number;
}

export interface MockOrder {
  id: string;
  userId: string;
  userName: string;
  vendorId: string;
  vendorName: string;
  items: OrderItem[];
  total: number;
  status: OrderStatus;
  placedAt: string;
  deliveredAt?: string;
  paymentMethod: string;
}

export interface MockTransaction {
  id: string;
  type: "order_payment" | "vendor_payout" | "refund" | "topup" | "commission";
  amount: number;
  from: string;
  to: string;
  date: string;
  orderId?: string;
}

export interface MockTicket {
  id: string;
  userId: string;
  userName: string;
  subject: string;
  status: TicketStatus;
  priority: "low" | "medium" | "high";
  createdAt: string;
  assignedTo?: string;
  messages: { sender: string; text: string; at: string }[];
}

export interface MockAuditEntry {
  id: string;
  admin: string;
  action: string;
  target: string;
  reason: string;
  timestamp: string;
}

// ---- Data ----

export const mockUsers: MockUser[] = [
  { id: "u1", name: "Aarav Sharma", email: "aarav@uni.edu", phone: "+91 98765 43210", status: "active", joinedAt: "2025-01-15", totalOrders: 47, totalSpent: 12400 },
  { id: "u2", name: "Priya Patel", email: "priya@uni.edu", phone: "+91 98765 43211", status: "active", joinedAt: "2025-02-03", totalOrders: 32, totalSpent: 8200 },
  { id: "u3", name: "Rohan Das", email: "rohan@uni.edu", phone: "+91 98765 43212", status: "blocked", joinedAt: "2025-01-20", totalOrders: 5, totalSpent: 1100 },
  { id: "u4", name: "Sneha Iyer", email: "sneha@uni.edu", phone: "+91 98765 43213", status: "active", joinedAt: "2025-03-10", totalOrders: 18, totalSpent: 4600 },
  { id: "u5", name: "Karan Singh", email: "karan@uni.edu", phone: "+91 98765 43214", status: "pending_deletion", joinedAt: "2025-01-05", totalOrders: 62, totalSpent: 15800 },
  { id: "u6", name: "Ananya Reddy", email: "ananya@uni.edu", phone: "+91 98765 43215", status: "active", joinedAt: "2025-04-01", totalOrders: 9, totalSpent: 2300 },
  { id: "u7", name: "Vikram Joshi", email: "vikram@uni.edu", phone: "+91 98765 43216", status: "active", joinedAt: "2025-02-18", totalOrders: 28, totalSpent: 7100 },
  { id: "u8", name: "Meera Nair", email: "meera@uni.edu", phone: "+91 98765 43217", status: "active", joinedAt: "2025-03-25", totalOrders: 15, totalSpent: 3800 },
  { id: "u9", name: "Arjun Mehta", email: "arjun@uni.edu", phone: "+91 98765 43218", status: "blocked", joinedAt: "2025-01-30", totalOrders: 3, totalSpent: 750 },
  { id: "u10", name: "Diya Kapoor", email: "diya@uni.edu", phone: "+91 98765 43219", status: "active", joinedAt: "2025-02-14", totalOrders: 41, totalSpent: 10500 },
  { id: "u11", name: "Sai Kumar", email: "sai@uni.edu", phone: "+91 98765 43220", status: "active", joinedAt: "2025-03-05", totalOrders: 22, totalSpent: 5600 },
  { id: "u12", name: "Ishita Gupta", email: "ishita@uni.edu", phone: "+91 98765 43221", status: "active", joinedAt: "2025-04-10", totalOrders: 7, totalSpent: 1900 },
];

export const mockVendors: MockVendor[] = [
  { id: "v1", name: "Campus Bites", ownerName: "Rajesh Kumar", email: "rajesh@campusbites.com", status: "approved", rating: 4.5, totalOrders: 1240, revenue: 372000, joinedAt: "2024-11-01", cuisine: "North Indian", payoutStatus: "completed", pendingPayout: 0 },
  { id: "v2", name: "Green Bowl", ownerName: "Anita Verma", email: "anita@greenbowl.com", status: "approved", rating: 4.7, totalOrders: 890, revenue: 267000, joinedAt: "2024-12-15", cuisine: "Salads & Bowls", payoutStatus: "pending", pendingPayout: 24500 },
  { id: "v3", name: "Chai Point", ownerName: "Suresh Menon", email: "suresh@chaipoint.com", status: "approved", rating: 4.3, totalOrders: 2100, revenue: 189000, joinedAt: "2024-10-20", cuisine: "Beverages", payoutStatus: "completed", pendingPayout: 0 },
  { id: "v4", name: "Pasta Palace", ownerName: "Marco Fernandez", email: "marco@pasta.com", status: "pending", rating: 0, totalOrders: 0, revenue: 0, joinedAt: "2025-04-12", cuisine: "Italian", payoutStatus: "pending", pendingPayout: 0 },
  { id: "v5", name: "Biryani House", ownerName: "Farhan Ali", email: "farhan@biryani.com", status: "approved", rating: 4.8, totalOrders: 1560, revenue: 468000, joinedAt: "2024-09-05", cuisine: "Hyderabadi", payoutStatus: "failed", pendingPayout: 38200 },
  { id: "v6", name: "Wrap & Roll", ownerName: "Neha Choudhary", email: "neha@wraproll.com", status: "suspended", rating: 3.2, totalOrders: 340, revenue: 85000, joinedAt: "2025-01-10", cuisine: "Wraps", payoutStatus: "pending", pendingPayout: 12800 },
  { id: "v7", name: "Juice Junction", ownerName: "Pooja Shetty", email: "pooja@juice.com", status: "rejected", rating: 0, totalOrders: 0, revenue: 0, joinedAt: "2025-03-28", cuisine: "Juices", payoutStatus: "pending", pendingPayout: 0 },
  { id: "v8", name: "Dosa Corner", ownerName: "Ramesh Rao", email: "ramesh@dosa.com", status: "approved", rating: 4.4, totalOrders: 780, revenue: 195000, joinedAt: "2025-01-22", cuisine: "South Indian", payoutStatus: "completed", pendingPayout: 0 },
];

export const mockOrders: MockOrder[] = [
  { id: "ord-001", userId: "u1", userName: "Aarav Sharma", vendorId: "v1", vendorName: "Campus Bites", items: [{ name: "Butter Chicken", qty: 1, price: 220 }, { name: "Naan", qty: 2, price: 40 }], total: 300, status: "delivered", placedAt: "2025-04-14T10:30:00Z", deliveredAt: "2025-04-14T11:05:00Z", paymentMethod: "wallet" },
  { id: "ord-002", userId: "u2", userName: "Priya Patel", vendorId: "v2", vendorName: "Green Bowl", items: [{ name: "Caesar Salad", qty: 1, price: 180 }], total: 180, status: "delivered", placedAt: "2025-04-14T11:00:00Z", deliveredAt: "2025-04-14T11:25:00Z", paymentMethod: "upi" },
  { id: "ord-003", userId: "u4", userName: "Sneha Iyer", vendorId: "v3", vendorName: "Chai Point", items: [{ name: "Masala Chai", qty: 3, price: 30 }, { name: "Samosa", qty: 2, price: 25 }], total: 140, status: "preparing", placedAt: "2025-04-14T12:15:00Z", paymentMethod: "wallet" },
  { id: "ord-004", userId: "u7", userName: "Vikram Joshi", vendorId: "v5", vendorName: "Biryani House", items: [{ name: "Chicken Biryani", qty: 2, price: 250 }], total: 500, status: "out_for_delivery", placedAt: "2025-04-14T12:30:00Z", paymentMethod: "card" },
  { id: "ord-005", userId: "u10", userName: "Diya Kapoor", vendorId: "v1", vendorName: "Campus Bites", items: [{ name: "Paneer Tikka", qty: 1, price: 200 }, { name: "Roti", qty: 3, price: 20 }], total: 260, status: "placed", placedAt: "2025-04-14T13:00:00Z", paymentMethod: "upi" },
  { id: "ord-006", userId: "u6", userName: "Ananya Reddy", vendorId: "v8", vendorName: "Dosa Corner", items: [{ name: "Masala Dosa", qty: 2, price: 120 }], total: 240, status: "cancelled", placedAt: "2025-04-13T18:00:00Z", paymentMethod: "wallet" },
  { id: "ord-007", userId: "u11", userName: "Sai Kumar", vendorId: "v3", vendorName: "Chai Point", items: [{ name: "Filter Coffee", qty: 4, price: 50 }], total: 200, status: "refunded", placedAt: "2025-04-13T09:00:00Z", paymentMethod: "upi" },
  { id: "ord-008", userId: "u8", userName: "Meera Nair", vendorId: "v2", vendorName: "Green Bowl", items: [{ name: "Quinoa Bowl", qty: 1, price: 220 }, { name: "Smoothie", qty: 1, price: 130 }], total: 350, status: "delivered", placedAt: "2025-04-13T13:00:00Z", deliveredAt: "2025-04-13T13:35:00Z", paymentMethod: "card" },
  { id: "ord-009", userId: "u1", userName: "Aarav Sharma", vendorId: "v5", vendorName: "Biryani House", items: [{ name: "Mutton Biryani", qty: 1, price: 320 }], total: 320, status: "delivered", placedAt: "2025-04-12T19:00:00Z", deliveredAt: "2025-04-12T19:40:00Z", paymentMethod: "wallet" },
  { id: "ord-010", userId: "u12", userName: "Ishita Gupta", vendorId: "v8", vendorName: "Dosa Corner", items: [{ name: "Rava Dosa", qty: 1, price: 100 }, { name: "Vada", qty: 2, price: 40 }], total: 180, status: "preparing", placedAt: "2025-04-14T13:30:00Z", paymentMethod: "upi" },
];

export const mockTransactions: MockTransaction[] = [
  { id: "tx-001", type: "order_payment", amount: 300, from: "Aarav Sharma", to: "Campus Bites", date: "2025-04-14", orderId: "ord-001" },
  { id: "tx-002", type: "commission", amount: 30, from: "Campus Bites", to: "Swift Platform", date: "2025-04-14", orderId: "ord-001" },
  { id: "tx-003", type: "vendor_payout", amount: 270, from: "Swift Platform", to: "Campus Bites", date: "2025-04-14" },
  { id: "tx-004", type: "order_payment", amount: 180, from: "Priya Patel", to: "Green Bowl", date: "2025-04-14", orderId: "ord-002" },
  { id: "tx-005", type: "refund", amount: 200, from: "Swift Platform", to: "Sai Kumar", date: "2025-04-13", orderId: "ord-007" },
  { id: "tx-006", type: "topup", amount: 500, from: "UPI", to: "Aarav Sharma Wallet", date: "2025-04-12" },
  { id: "tx-007", type: "order_payment", amount: 500, from: "Vikram Joshi", to: "Biryani House", date: "2025-04-14", orderId: "ord-004" },
  { id: "tx-008", type: "vendor_payout", amount: 42000, from: "Swift Platform", to: "Biryani House", date: "2025-04-10" },
  { id: "tx-009", type: "commission", amount: 4680, from: "Biryani House", to: "Swift Platform", date: "2025-04-10" },
  { id: "tx-010", type: "order_payment", amount: 350, from: "Meera Nair", to: "Green Bowl", date: "2025-04-13", orderId: "ord-008" },
];

export const mockTickets: MockTicket[] = [
  { id: "tkt-001", userId: "u1", userName: "Aarav Sharma", subject: "Order arrived cold", status: "open", priority: "high", createdAt: "2025-04-14T11:30:00Z", messages: [{ sender: "Aarav Sharma", text: "My butter chicken order arrived cold. Very disappointing.", at: "2025-04-14T11:30:00Z" }] },
  { id: "tkt-002", userId: "u6", userName: "Ananya Reddy", subject: "Refund not received", status: "in_progress", priority: "high", createdAt: "2025-04-13T19:00:00Z", assignedTo: "Swift Admin", messages: [{ sender: "Ananya Reddy", text: "I cancelled my order but haven't received my refund yet.", at: "2025-04-13T19:00:00Z" }, { sender: "Swift Admin", text: "Looking into this for you. Your refund should be processed within 24 hours.", at: "2025-04-13T20:00:00Z" }] },
  { id: "tkt-003", userId: "u3", userName: "Rohan Das", subject: "Account blocked unfairly", status: "open", priority: "medium", createdAt: "2025-04-14T08:00:00Z", messages: [{ sender: "Rohan Das", text: "My account has been blocked but I haven't violated any rules.", at: "2025-04-14T08:00:00Z" }] },
  { id: "tkt-004", userId: "u8", userName: "Meera Nair", subject: "Wrong items delivered", status: "resolved", priority: "medium", createdAt: "2025-04-12T15:00:00Z", assignedTo: "Swift Admin", messages: [{ sender: "Meera Nair", text: "Received wrong items in my order.", at: "2025-04-12T15:00:00Z" }, { sender: "Swift Admin", text: "We've processed a full refund and notified the vendor.", at: "2025-04-12T16:30:00Z" }] },
  { id: "tkt-005", userId: "u11", userName: "Sai Kumar", subject: "App crashes on checkout", status: "closed", priority: "low", createdAt: "2025-04-10T10:00:00Z", assignedTo: "Swift Admin", messages: [{ sender: "Sai Kumar", text: "The app keeps crashing when I try to check out.", at: "2025-04-10T10:00:00Z" }, { sender: "Swift Admin", text: "This has been fixed in the latest update. Please update your app.", at: "2025-04-11T09:00:00Z" }] },
];

export const mockAuditLog: MockAuditEntry[] = [
  { id: "aud-001", admin: "Swift Admin", action: "block_user", target: "Rohan Das (u3)", reason: "Multiple reports of abusive behavior towards delivery partners", timestamp: "2025-04-13T14:00:00Z" },
  { id: "aud-002", admin: "Swift Admin", action: "approve_vendor", target: "Dosa Corner (v8)", reason: "All documents verified and hygiene certificate valid", timestamp: "2025-04-12T10:00:00Z" },
  { id: "aud-003", admin: "Swift Admin", action: "reject_vendor", target: "Juice Junction (v7)", reason: "Incomplete documentation and failed hygiene inspection", timestamp: "2025-04-11T16:00:00Z" },
  { id: "aud-004", admin: "Swift Admin", action: "cancel_order", target: "Order ord-006", reason: "Vendor confirmed out of stock for ordered items", timestamp: "2025-04-13T18:15:00Z" },
  { id: "aud-005", admin: "Swift Admin", action: "process_refund", target: "Order ord-007 (Sai Kumar)", reason: "Customer complaint verified — wrong items delivered initially", timestamp: "2025-04-13T09:30:00Z" },
  { id: "aud-006", admin: "Swift Admin", action: "suspend_vendor", target: "Wrap & Roll (v6)", reason: "Multiple food quality complaints and low hygiene score", timestamp: "2025-04-10T11:00:00Z" },
  { id: "aud-007", admin: "Swift Admin", action: "update_settings", target: "Commission Rate", reason: "Adjusted platform commission from 8% to 10% per board decision", timestamp: "2025-04-09T09:00:00Z" },
  { id: "aud-008", admin: "Swift Admin", action: "block_user", target: "Arjun Mehta (u9)", reason: "Fraudulent payment attempts detected", timestamp: "2025-04-08T15:00:00Z" },
  { id: "aud-009", admin: "Swift Admin", action: "unblock_user", target: "Test User", reason: "Appeal reviewed and accepted — violation was a misunderstanding", timestamp: "2025-04-07T12:00:00Z" },
  { id: "aud-010", admin: "Swift Admin", action: "vendor_payout", target: "Campus Bites (v1)", reason: "Weekly payout processed successfully", timestamp: "2025-04-14T08:00:00Z" },
];

// KPI helpers
export const kpi = {
  totalUsers: mockUsers.length,
  activeUsers: mockUsers.filter((u) => u.status === "active").length,
  activeVendors: mockVendors.filter((v) => v.status === "approved").length,
  ordersToday: mockOrders.filter((o) => o.placedAt.startsWith("2025-04-14")).length,
  revenueMTD: mockOrders.reduce((s, o) => s + o.total, 0),
  totalRevenue: mockVendors.reduce((s, v) => s + v.revenue, 0),
  platformCommission: Math.round(mockVendors.reduce((s, v) => s + v.revenue, 0) * 0.1),
  pendingPayouts: mockVendors.reduce((s, v) => s + v.pendingPayout, 0),
  openTickets: mockTickets.filter((t) => t.status === "open" || t.status === "in_progress").length,
};

export const revenueChartData = [
  { date: "Apr 1", revenue: 42000, orders: 140 },
  { date: "Apr 2", revenue: 38000, orders: 125 },
  { date: "Apr 3", revenue: 45000, orders: 155 },
  { date: "Apr 4", revenue: 41000, orders: 138 },
  { date: "Apr 5", revenue: 47000, orders: 162 },
  { date: "Apr 6", revenue: 52000, orders: 178 },
  { date: "Apr 7", revenue: 49000, orders: 170 },
  { date: "Apr 8", revenue: 44000, orders: 148 },
  { date: "Apr 9", revenue: 46000, orders: 158 },
  { date: "Apr 10", revenue: 51000, orders: 175 },
  { date: "Apr 11", revenue: 48000, orders: 165 },
  { date: "Apr 12", revenue: 53000, orders: 182 },
  { date: "Apr 13", revenue: 50000, orders: 172 },
  { date: "Apr 14", revenue: 34000, orders: 118 },
];
