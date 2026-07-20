import { Link } from 'react-router-dom'
import { Dumbbell } from 'lucide-react'

const COLUMNS = [
  {
    title: 'Sản phẩm',
    links: [
      { label: 'Tính năng', href: '/#features' },
      { label: 'Cách hoạt động', href: '/#how-it-works' },
      { label: 'Bảng giá', href: '/#pricing' },
      { label: 'Câu hỏi thường gặp', href: '/#faq' },
    ],
  },
  {
    title: 'Tài khoản',
    links: [
      { label: 'Đăng nhập', href: '/login' },
      { label: 'Đăng ký', href: '/register' },
      { label: 'Nâng cấp Premium', href: '/checkout' },
    ],
  },
]

export default function Footer() {
  return (
    <footer className="border-t border-brand-hairline bg-brand-canvasSoft">
      <div className="mx-auto max-w-6xl px-6 py-14">
        <div className="grid gap-10 sm:grid-cols-2 lg:grid-cols-4">
          <div>
            <div className="mb-3 flex items-center gap-2 text-base font-bold text-brand-ink">
              <span className="flex h-7 w-7 items-center justify-center rounded-md bg-brand-primary">
                <Dumbbell className="h-3.5 w-3.5 text-white" />
              </span>
              GymSup
            </div>
            <p className="max-w-[220px] text-sm text-brand-inkMuted">
              Ứng dụng tập luyện có AI Coach đồng hành: tạo lịch tập, phân tích form và theo dõi tiến bộ theo từng nhóm cơ.
            </p>
          </div>

          {COLUMNS.map((col) => (
            <div key={col.title}>
              <h3 className="mb-3 text-sm font-semibold text-brand-ink">{col.title}</h3>
              <ul className="space-y-2.5">
                {col.links.map((link) => (
                  <li key={link.label}>
                    {link.href.startsWith('/#') ? (
                      <a href={link.href} className="text-sm text-brand-inkMuted hover:text-brand-ink">
                        {link.label}
                      </a>
                    ) : (
                      <Link to={link.href} className="text-sm text-brand-inkMuted hover:text-brand-ink">
                        {link.label}
                      </Link>
                    )}
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        <div className="mt-12 border-t border-brand-hairline pt-6 text-sm text-brand-inkFaint">
          © {new Date().getFullYear()} GymSup. Đã đăng ký bản quyền.
        </div>
      </div>
    </footer>
  )
}
