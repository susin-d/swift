-- Migration: Real-time Chat & Support System

-- ChatRoom
CREATE TABLE IF NOT EXISTS chat_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT CHECK (type IN ('user-vendor', 'user-delivery', 'support', 'group')),
  order_id UUID NULL,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- ChatRoom Participants
CREATE TABLE IF NOT EXISTS chat_room_participants (
  room_id UUID REFERENCES chat_rooms(id),
  user_id UUID NULL,
  vendor_id UUID NULL,
  delivery_agent_id UUID NULL,
  admin_id UUID NULL,
  joined_at TIMESTAMP DEFAULT now(),
  PRIMARY KEY (room_id, user_id, vendor_id, delivery_agent_id, admin_id)
);

-- ChatMessage
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID REFERENCES chat_rooms(id),
  sender_type TEXT CHECK (sender_type IN ('user', 'vendor', 'delivery', 'admin')),
  sender_id UUID,
  message TEXT,
  sent_at TIMESTAMP DEFAULT now(),
  is_read BOOLEAN DEFAULT FALSE
);

-- SupportTicket
CREATE TABLE IF NOT EXISTS support_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID,
  user_id UUID,
  status TEXT CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now(),
  subject TEXT,
  description TEXT
);
