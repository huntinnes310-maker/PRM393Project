import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  MessageCircle,
  BrainCircuit,
  ScanEye,
  Dumbbell,
  CalendarClock,
  ShieldOff,
  Check,
  ChevronDown,
} from 'lucide-react'
import { getActivePlans } from '../services/subscriptionService.js'
import { useAuth } from '../context/AuthContext.jsx'

const STATS = [
  { value: '6+', label: 'nhóm cơ theo dõi riêng biệt' },
  { value: '3', label: 'chế độ phân tích AI' },
  { value: '7', label: 'cấp bậc thành tích, từ Sắt đến Huyền thoại' },
  { value: '24/7', label: 'AI Coach đồng hành' },
]

const FEATURES = [
  {
    icon: MessageCircle,
    color: 'bg-sticker-teal',
    title: 'AI Coach trò chuyện',
    desc: 'Hỏi đáp về tập luyện, dinh dưỡng và phục hồi bất cứ lúc nào — miễn phí, không giới hạn tính năng cơ bản.',
  },
  {
    icon: BrainCircuit,
    color: 'bg-sticker-purple',
    title: 'AI tự tạo lịch tập',
    desc: 'AI thiết kế lịch tập cá nhân hoá theo Upper/Lower Split, phù hợp mục tiêu, kinh nghiệm và thời gian của bạn.',
  },
  {
    icon: ScanEye,
    color: 'bg-sticker-orange',
    title: 'Phân tích ảnh & video',
    desc: 'Chụp vóc dáng, quay video tập để AI đánh giá form và gợi ý bài tập phù hợp với thiết bị hiện có.',
  },
  {
    icon: Dumbbell,
    color: 'bg-sticker-pink',
    title: 'Theo dõi từng nhóm cơ',
    desc: 'Mỗi nhóm cơ có cấp bậc và thanh kinh nghiệm riêng, giúp bạn thấy rõ nhóm nào đang tiến bộ, nhóm nào cần chú ý.',
  },
  {
    icon: CalendarClock,
    color: 'bg-sticker-sky',
    title: 'Lịch tập tuỳ chỉnh',
    desc: 'Tự xây dựng lịch tập riêng theo từng buổi, từng bài tập, hoặc để AI đề xuất rồi chỉnh sửa lại theo ý bạn.',
  },
  {
    icon: ShieldOff,
    color: 'bg-sticker-green',
    title: 'Không quảng cáo',
    desc: 'Hội viên Premium tập luyện không bị gián đoạn bởi quảng cáo, cùng toàn quyền truy cập tính năng AI.',
  },
]

const STEPS = [
  {
    number: '1',
    title: 'Khai báo mục tiêu',
    desc: 'Đăng ký tài khoản và cho AI biết chiều cao, cân nặng, mục tiêu và kinh nghiệm tập luyện của bạn.',
  },
  {
    number: '2',
    title: 'AI thiết kế lịch tập',
    desc: 'AI Coach tạo lịch tập cá nhân hoá, hoặc bạn tự xây dựng lịch riêng và chỉnh sửa bất cứ lúc nào.',
  },
  {
    number: '3',
    title: 'Tập & theo dõi tiến bộ',
    desc: 'Ghi lại từng buổi tập, xem cấp bậc mỗi nhóm cơ tăng dần theo thời gian và điều chỉnh khi cần.',
  },
]

const FAQS = [
  {
    q: 'GymSup có miễn phí không?',
    a: 'Có. Bạn dùng miễn phí để trò chuyện với AI Coach. Nâng cấp Premium để mở khoá AI tự tạo lịch tập, phân tích ảnh/video và loại bỏ quảng cáo.',
  },
  {
    q: 'AI Coach hoạt động như thế nào?',
    a: 'AI dựa trên hồ sơ của bạn (mục tiêu, kinh nghiệm, thể trạng) để tư vấn và thiết kế lịch tập theo phương pháp Upper/Lower Split phù hợp với số buổi tập mỗi tuần.',
  },
  {
    q: 'Dữ liệu tập luyện của tôi có được lưu lại không?',
    a: 'Có. Mọi buổi tập bạn ghi lại đều được lưu để tính cấp bậc và kinh nghiệm của từng nhóm cơ theo thời gian.',
  },
  {
    q: 'Tôi có thể huỷ gói Premium bất cứ lúc nào không?',
    a: 'Có. Bạn có thể huỷ bất cứ lúc nào — gói vẫn tiếp tục hoạt động tới hết chu kỳ đã thanh toán.',
  },
]

function formatVnd(amount) {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount)
}

export default function Home() {
  const [plans, setPlans] = useState([])
  const [plansLoaded, setPlansLoaded] = useState(false)
  const { user } = useAuth()
  const navigate = useNavigate()

  useEffect(() => {
    getActivePlans()
      .then(setPlans)
      .catch(() => setPlans([]))
      .finally(() => setPlansLoaded(true))
  }, [])

  const featuredIndex = plans.length >= 3 ? Math.floor((plans.length - 1) / 2) : -1

  return (
    <div>
      {/* Hero — the single dark "night" band per the design system */}
      <section className="relative overflow-hidden bg-brand-secondary">
        <div
          className="absolute inset-0 bg-cover bg-center opacity-30"
          style={{
            backgroundImage:
              "url('https://images.pexels.com/photos/1552249/pexels-photo-1552249.jpeg?auto=compress&cs=tinysrgb&w=1600')",
          }}
        />
        <div className="absolute inset-0 bg-gradient-to-b from-brand-secondary/40 via-brand-secondary/80 to-brand-secondary" />

        <div className="relative mx-auto grid max-w-6xl gap-12 px-6 py-20 lg:grid-cols-2 lg:items-center lg:py-28">
          <div>
            <span className="badge-pill mb-6">
              <Dumbbell className="h-3.5 w-3.5" />
              AI Coach cho hành trình tập luyện
            </span>
            <h1 className="mb-5 text-4xl font-bold leading-[1.05] tracking-tight text-white sm:text-5xl lg:text-6xl">
              Tập đúng hơn.
              <br />
              Tiến bộ rõ ràng hơn.
            </h1>
            <p className="mb-8 max-w-lg text-base leading-relaxed text-white/80">
              GymSup đồng hành cùng bạn với AI Coach trò chuyện, tự tạo lịch tập cá nhân hoá,
              phân tích form qua ảnh/video và theo dõi tiến bộ theo từng nhóm cơ riêng biệt.
            </p>
            <div className="flex flex-wrap items-center gap-4">
              <button
                onClick={() => navigate('/tai-app')}
                className="btn-primary px-6 py-3 text-base"
              >
                Dùng thử miễn phí
              </button>
              <a href="#pricing" className="btn-secondary px-6 py-3 text-base">
                Xem bảng giá
              </a>
            </div>
          </div>

          {/* Floating light "app preview" panel — real product concepts, not a stock screenshot */}
          <div className="relative mx-auto w-full max-w-sm">
            <div className="rounded-xl bg-white p-5 shadow-elevated">
              <div className="mb-4 flex items-center gap-2 rounded-lg bg-brand-canvasSoft p-3">
                <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-brand-primary">
                  <MessageCircle className="h-4 w-4 text-white" />
                </span>
                <p className="text-sm text-brand-inkSecondary">
                  Bạn có <strong className="text-brand-ink">4 buổi tập</strong> tuần này. Bắt đầu buổi Upper Body nhé? 💪
                </p>
              </div>

              <p className="mb-3 text-xs font-semibold uppercase tracking-wide text-brand-inkFaint">
                Tiến độ nhóm cơ
              </p>
              <div className="space-y-3">
                {[
                  { name: 'Ngực · Cấp 12', pct: 72, color: 'bg-sticker-teal' },
                  { name: 'Lưng · Cấp 9', pct: 54, color: 'bg-sticker-purple' },
                  { name: 'Chân · Cấp 7', pct: 38, color: 'bg-sticker-orange' },
                ].map((m) => (
                  <div key={m.name}>
                    <div className="mb-1 flex items-center justify-between text-xs text-brand-inkSecondary">
                      <span>{m.name}</span>
                      <span>{m.pct}%</span>
                    </div>
                    <div className="h-1.5 w-full overflow-hidden rounded-full bg-brand-canvasSoft">
                      <div className={`h-full ${m.color}`} style={{ width: `${m.pct}%` }} />
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <span className="badge-pill absolute -right-3 -top-3 shadow-soft">Premium</span>
          </div>
        </div>
      </section>

      {/* Stats */}
      <section className="border-b border-brand-hairline bg-white">
        <div className="mx-auto grid max-w-6xl grid-cols-2 gap-8 px-6 py-10 lg:grid-cols-4">
          {STATS.map((s) => (
            <div key={s.label} className="text-center lg:text-left">
              <p className="text-3xl font-bold text-brand-primary">{s.value}</p>
              <p className="mt-1 text-sm text-brand-inkMuted">{s.label}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Features */}
      <section id="features" className="mx-auto max-w-6xl px-6 py-20">
        <div className="mx-auto mb-14 max-w-2xl text-center">
          <span className="badge-pill mb-4 bg-brand-canvasSoft">Tính năng</span>
          <h2 className="mb-4 text-3xl font-bold tracking-tight text-brand-ink sm:text-4xl">
            Mọi công cụ để tập luyện hiệu quả hơn
          </h2>
          <p className="text-brand-inkMuted">
            Từ trò chuyện với AI đến theo dõi tiến bộ chi tiết — được thiết kế quanh cách bạn thực sự tập luyện.
          </p>
        </div>

        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {FEATURES.map(({ icon: Icon, title, desc, color }) => (
            <div key={title} className="feature-card text-left">
              <div className={`mb-4 flex h-11 w-11 items-center justify-center rounded-md ${color}`}>
                <Icon className="h-5 w-5 text-white" />
              </div>
              <h3 className="mb-2 text-lg font-semibold text-brand-ink">{title}</h3>
              <p className="text-sm leading-relaxed text-brand-inkMuted">{desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Photo gallery — real fitness imagery, outside the hero banner */}
      <section className="border-y border-brand-hairline bg-white">
        <div className="mx-auto max-w-6xl px-6 py-16">
          <div className="grid gap-5 sm:grid-cols-3">
            {[
              {
                src: 'https://images.pexels.com/photos/1954524/pexels-photo-1954524.jpeg?auto=compress&cs=tinysrgb&w=800',
                caption: 'Tập kháng lực đúng form',
              },
              {
                src: 'https://images.pexels.com/photos/4761792/pexels-photo-4761792.jpeg?auto=compress&cs=tinysrgb&w=800',
                caption: 'Theo dõi tiến bộ mỗi buổi tập',
              },
              {
                src: 'https://images.pexels.com/photos/3823039/pexels-photo-3823039.jpeg?auto=compress&cs=tinysrgb&w=800',
                caption: 'Giãn cơ và phục hồi hợp lý',
              },
            ].map((photo) => (
              <div key={photo.src} className="group overflow-hidden rounded-lg border border-brand-hairline">
                <div className="aspect-[4/3] overflow-hidden">
                  <img
                    src={photo.src}
                    alt={photo.caption}
                    loading="lazy"
                    className="h-full w-full object-cover transition-transform duration-300 group-hover:scale-105"
                  />
                </div>
                <p className="px-4 py-3 text-sm text-brand-inkMuted">{photo.caption}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* How it works */}
      <section id="how-it-works" className="border-y border-brand-hairline bg-white">
        <div className="mx-auto max-w-6xl px-6 py-20">
          <div className="mx-auto mb-14 max-w-2xl text-center">
            <span className="badge-pill mb-4 bg-brand-canvasSoft">Cách hoạt động</span>
            <h2 className="text-3xl font-bold tracking-tight text-brand-ink sm:text-4xl">
              Bắt đầu chỉ trong 3 bước
            </h2>
          </div>

          <div className="grid gap-10 sm:grid-cols-3">
            {STEPS.map((step) => (
              <div key={step.number} className="text-center sm:text-left">
                <span className="mb-4 inline-flex h-10 w-10 items-center justify-center rounded-full bg-brand-primary text-sm font-bold text-white">
                  {step.number}
                </span>
                <h3 className="mb-2 text-lg font-semibold text-brand-ink">{step.title}</h3>
                <p className="text-sm leading-relaxed text-brand-inkMuted">{step.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Pricing */}
      <section id="pricing" className="mx-auto max-w-6xl px-6 py-20">
        <div className="mx-auto mb-14 max-w-2xl text-center">
          <span className="badge-pill mb-4 bg-brand-canvasSoft">Bảng giá</span>
          <h2 className="mb-4 text-3xl font-bold tracking-tight text-brand-ink sm:text-4xl">
            Chọn gói phù hợp với bạn
          </h2>
          <p className="text-brand-inkMuted">Bắt đầu miễn phí, nâng cấp bất cứ lúc nào bạn muốn nhiều hơn.</p>
        </div>

        {plansLoaded && plans.length === 0 ? (
          <p className="text-center text-sm text-brand-inkMuted">
            Bảng giá hiện chưa sẵn sàng, vui lòng quay lại sau.
          </p>
        ) : (
          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {plans.map((plan, i) => {
              const featured = i === featuredIndex
              return (
                <div
                  key={plan.id}
                  className={`flex flex-col rounded-md border p-6 ${
                    featured ? 'border-brand-primary bg-brand-canvasSoft' : 'border-brand-hairline bg-white'
                  }`}
                >
                  {featured && <span className="badge-pill mb-4 w-fit">Đề xuất</span>}
                  <h3 className="mb-1 text-lg font-bold text-brand-ink">{plan.name}</h3>
                  <p className="mb-1 text-3xl font-bold text-brand-ink">{formatVnd(plan.price)}</p>
                  <p className="mb-6 flex items-center gap-2 text-sm text-brand-inkMuted">
                    <Check className="h-4 w-4 text-brand-success" />
                    {plan.durationMonths} tháng
                  </p>
                  <button
                    onClick={() => navigate(user ? '/checkout' : '/register')}
                    className={featured ? 'btn-primary mt-auto' : 'btn-utility mt-auto'}
                  >
                    Chọn gói
                  </button>
                </div>
              )
            })}
          </div>
        )}
      </section>

      {/* FAQ */}
      <section id="faq" className="border-t border-brand-hairline bg-white">
        <div className="mx-auto max-w-3xl px-6 py-20">
          <div className="mx-auto mb-12 max-w-2xl text-center">
            <span className="badge-pill mb-4 bg-brand-canvasSoft">Câu hỏi thường gặp</span>
            <h2 className="text-3xl font-bold tracking-tight text-brand-ink sm:text-4xl">
              Còn thắc mắc?
            </h2>
          </div>

          <div className="space-y-3">
            {FAQS.map((item) => (
              <details key={item.q} className="group rounded-lg border border-brand-hairline p-5">
                <summary className="flex cursor-pointer list-none items-center justify-between font-medium text-brand-ink">
                  {item.q}
                  <ChevronDown className="h-4 w-4 shrink-0 text-brand-inkMuted transition-transform group-open:rotate-180" />
                </summary>
                <p className="mt-3 text-sm leading-relaxed text-brand-inkMuted">{item.a}</p>
              </details>
            ))}
          </div>
        </div>
      </section>

      {/* Final CTA — light surface, per spec's rule against repeating the dark hero band */}
      <section className="mx-auto max-w-6xl px-6 py-20">
        <div className="feature-card-elevated flex flex-col items-center gap-6 px-8 py-14 text-center">
          <h2 className="text-3xl font-bold tracking-tight text-brand-ink sm:text-4xl">
            Sẵn sàng bắt đầu hành trình?
          </h2>
          <p className="max-w-md text-brand-inkMuted">
            Tạo tài khoản miễn phí và để AI Coach đồng hành cùng bạn ngay hôm nay.
          </p>
          <button
            onClick={() => navigate('/tai-app')}
            className="btn-primary px-6 py-3 text-base"
          >
            Dùng thử miễn phí
          </button>
        </div>
      </section>
    </div>
  )
}
