import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { Dumbbell, Sparkles, Menu, X } from 'lucide-react'
import { useAuth } from '../../context/AuthContext.jsx'
import UpgradeModal from '../UpgradeModal.jsx'

const NAV_LINKS = [
  { label: 'Tính năng', href: '/#features' },
  { label: 'Cách hoạt động', href: '/#how-it-works' },
  { label: 'Bảng giá', href: '/#pricing' },
  { label: 'Câu hỏi thường gặp', href: '/#faq' },
]

export default function Header() {
  const { user, isPremium, loading, logout } = useAuth()
  const [showUpgrade, setShowUpgrade] = useState(false)
  const [mobileOpen, setMobileOpen] = useState(false)
  const navigate = useNavigate()

  return (
    <>
      <header className="sticky top-0 z-40 border-b border-brand-hairline bg-brand-canvas">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
          <Link to="/" className="flex items-center gap-2 text-lg font-bold tracking-tight text-brand-ink">
            <span className="flex h-8 w-8 items-center justify-center rounded-md bg-brand-primary">
              <Dumbbell className="h-4 w-4 text-white" />
            </span>
            GymSup
          </Link>

          <nav className="hidden items-center gap-7 text-sm text-brand-inkSecondary lg:flex">
            {NAV_LINKS.map((link) => (
              <a key={link.href} href={link.href} className="transition-colors hover:text-brand-ink">
                {link.label}
              </a>
            ))}
          </nav>

          <div className="hidden items-center gap-4 lg:flex">
            {loading ? null : user ? (
              <>
                <Link to="/dashboard" className="text-sm font-medium text-brand-inkSecondary hover:text-brand-ink">
                  Bảng điều khiển
                </Link>
                {!isPremium && (
                  <button onClick={() => setShowUpgrade(true)} className="btn-utility">
                    <Sparkles className="h-3.5 w-3.5" />
                    Nâng cấp
                  </button>
                )}
                <span className="text-sm font-medium text-brand-inkSecondary">
                  {user.fullName || user.email}
                </span>
                <button onClick={logout} className="text-sm text-brand-inkMuted hover:text-brand-ink">
                  Đăng xuất
                </button>
              </>
            ) : (
              <>
                <button onClick={() => navigate('/login')} className="text-sm font-medium text-brand-inkSecondary hover:text-brand-ink">
                  Đăng nhập
                </button>
                <button onClick={() => navigate('/tai-app')} className="btn-utility">
                  Dùng thử miễn phí
                </button>
              </>
            )}
          </div>

          <button
            onClick={() => setMobileOpen((v) => !v)}
            className="flex h-9 w-9 items-center justify-center rounded-md text-brand-ink lg:hidden"
            aria-label="Mở menu"
          >
            {mobileOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
          </button>
        </div>

        {mobileOpen && (
          <div className="border-t border-brand-hairline bg-brand-canvas px-6 py-4 lg:hidden">
            <nav className="flex flex-col gap-4 text-sm text-brand-inkSecondary">
              {NAV_LINKS.map((link) => (
                <a key={link.href} href={link.href} onClick={() => setMobileOpen(false)} className="hover:text-brand-ink">
                  {link.label}
                </a>
              ))}
            </nav>
            <div className="mt-4 flex flex-col gap-3 border-t border-brand-hairline pt-4">
              {loading ? null : user ? (
                <>
                  <Link
                    to="/dashboard"
                    onClick={() => setMobileOpen(false)}
                    className="text-left text-sm font-medium text-brand-inkSecondary"
                  >
                    Bảng điều khiển
                  </Link>
                  {!isPremium && (
                    <button onClick={() => setShowUpgrade(true)} className="btn-utility w-full">
                      <Sparkles className="h-3.5 w-3.5" />
                      Nâng cấp
                    </button>
                  )}
                  <button onClick={logout} className="text-left text-sm text-brand-inkMuted">
                    Đăng xuất ({user.fullName || user.email})
                  </button>
                </>
              ) : (
                <>
                  <button onClick={() => navigate('/login')} className="text-left text-sm font-medium text-brand-inkSecondary">
                    Đăng nhập
                  </button>
                  <button onClick={() => navigate('/tai-app')} className="btn-primary w-full">
                    Dùng thử miễn phí
                  </button>
                </>
              )}
            </div>
          </div>
        )}
      </header>

      <UpgradeModal open={showUpgrade} onClose={() => setShowUpgrade(false)} />
    </>
  )
}
