const TIERS = {
  Iron: { color: '#6B7280', label: 'Sắt' },
  Bronze: { color: '#B87333', label: 'Đồng' },
  Silver: { color: '#9CA3AF', label: 'Bạc' },
  Gold: { color: '#D4AF37', label: 'Vàng' },
  Platinum: { color: '#5EEAD4', label: 'Bạch kim' },
  Diamond: { color: '#38BDF8', label: 'Kim cương' },
  Champion: { color: '#A855F7', label: 'Huyền thoại' },
}

export function getTierMeta(tier) {
  return TIERS[tier] ?? { color: '#9CA3AF', label: tier || 'Chưa xếp hạng' }
}

export const TIER_ORDER = ['Iron', 'Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond', 'Champion']
