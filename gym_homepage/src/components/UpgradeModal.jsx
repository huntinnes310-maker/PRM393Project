import { useNavigate } from 'react-router-dom'
import { X, Check } from 'lucide-react'

const FEATURES = [
  'Không quảng cáo',
  'AI phân tích thiết bị tập',
  'Form tập chuẩn cho từng bài',
  'AI tạo lịch tập cá nhân hoá',
]

export default function UpgradeModal({ open, onClose }) {
  const navigate = useNavigate()
  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 animate-fade-in">
      <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-elevated animate-slide-up">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-xl font-bold text-brand-ink">Nâng cấp Premium</h2>
          <button onClick={onClose} className="text-brand-inkMuted hover:text-brand-ink">
            <X className="h-5 w-5" />
          </button>
        </div>

        <p className="mb-4 text-sm text-brand-inkMuted">
          Mở khoá toàn bộ tính năng cao cấp của GymSup:
        </p>

        <ul className="mb-6 space-y-3">
          {FEATURES.map((feature) => (
            <li key={feature} className="flex items-center gap-3 text-sm text-brand-ink">
              <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-brand-primary/10 text-brand-primary">
                <Check className="h-3.5 w-3.5" />
              </span>
              {feature}
            </li>
          ))}
        </ul>

        <button
          onClick={() => {
            onClose()
            navigate('/checkout')
          }}
          className="btn-primary w-full"
        >
          Nâng cấp ngay
        </button>
      </div>
    </div>
  )
}
