import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { Flame, Dumbbell, Award, Sparkles, CalendarDays } from 'lucide-react'
import { useAuth } from '../context/AuthContext.jsx'
import { getHomeData } from '../services/homeService.js'
import { getCustomerProfile } from '../services/customerService.js'
import { getTierMeta } from '../utils/muscleTier.js'

function formatDate(value) {
  if (!value) return ''
  return new Intl.DateTimeFormat('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' }).format(
    new Date(value),
  )
}

function formatDuration(totalSeconds) {
  if (!totalSeconds) return '—'
  const minutes = Math.round(totalSeconds / 60)
  if (minutes < 60) return `${minutes} phút`
  return `${Math.floor(minutes / 60)}h${minutes % 60 ? ` ${minutes % 60}p` : ''}`
}

const STATUS_STYLE = {
  COMPLETED: { label: 'Hoàn thành', className: 'bg-sticker-green/15 text-sticker-green' },
  IN_PROGRESS: { label: 'Đang tập', className: 'bg-sticker-sky/15 text-brand-primary' },
}

function statusMeta(status) {
  return STATUS_STYLE[status] ?? { label: status || '—', className: 'bg-brand-canvasSoft text-brand-inkMuted' }
}

export default function Dashboard() {
  const { user, subscription, isPremium } = useAuth()
  const [home, setHome] = useState(null)
  const [profile, setProfile] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    if (!user?.userId) return
    let cancelled = false
    setLoading(true)
    Promise.all([getHomeData(user.userId), getCustomerProfile(user.userId)])
      .then(([homeData, profileData]) => {
        if (cancelled) return
        setHome(homeData)
        setProfile(profileData)
      })
      .catch(() => {
        if (!cancelled) setError('Không thể tải dữ liệu. Vui lòng thử lại.')
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })
    return () => {
      cancelled = true
    }
  }, [user?.userId])

  const topMuscles = useMemo(() => {
    if (!home?.muscleProgress) return []
    return [...home.muscleProgress].sort((a, b) => b.totalExp - a.totalExp).slice(0, 8)
  }, [home])

  const recentHistory = useMemo(() => {
    if (!home?.history) return []
    return [...home.history]
      .sort((a, b) => new Date(b.startTime) - new Date(a.startTime))
      .slice(0, 5)
  }, [home])

  if (loading) {
    return (
      <div className="mx-auto flex min-h-[60vh] max-w-6xl items-center justify-center px-6">
        <p className="text-brand-inkMuted">Đang tải bảng điều khiển...</p>
      </div>
    )
  }

  if (error) {
    return (
      <div className="mx-auto flex min-h-[60vh] max-w-6xl items-center justify-center px-6 text-center">
        <p className="text-brand-danger">{error}</p>
      </div>
    )
  }

  return (
    <div className="mx-auto max-w-6xl px-6 py-10">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-brand-ink sm:text-3xl">
          Chào mừng trở lại, {profile?.fullName || user?.fullName || 'bạn'} 👋
        </h1>
        <p className="mt-1 text-sm text-brand-inkMuted">Đây là tổng quan tiến độ tập luyện của bạn.</p>
      </div>

      <div className="mb-8 grid gap-6 lg:grid-cols-3">
        {/* Profile card */}
        <div className="feature-card lg:col-span-2">
          <div className="mb-5 flex items-center gap-4">
            <span className="flex h-14 w-14 items-center justify-center rounded-full bg-brand-primary text-lg font-bold text-white">
              {(profile?.fullName || user?.email || '?').charAt(0).toUpperCase()}
            </span>
            <div>
              <p className="font-semibold text-brand-ink">{profile?.fullName || user?.fullName}</p>
              <p className="text-sm text-brand-inkMuted">{profile?.email || user?.email}</p>
            </div>
          </div>

          {profile ? (
            <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
              <Stat label="Chiều cao" value={profile.heightCm ? `${profile.heightCm} cm` : '—'} />
              <Stat label="Cân nặng" value={profile.weightKg ? `${profile.weightKg} kg` : '—'} />
              <Stat label="BMI" value={profile.bmi ? profile.bmi.toFixed(1) : '—'} />
              <Stat label="Mục tiêu" value={profile.goal || '—'} />
            </div>
          ) : (
            <p className="text-sm text-brand-inkMuted">
              Bạn chưa khai báo hồ sơ thể trạng. Hoàn tất hồ sơ trong ứng dụng di động để xem đầy đủ thông tin tại đây.
            </p>
          )}
        </div>

        {/* Subscription card */}
        <div className="feature-card flex flex-col">
          <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-brand-inkFaint">Gói hội viên</p>
          {subscription ? (
            <>
              <p className="mb-1 text-xl font-bold text-brand-ink">{subscription.planName}</p>
              <p className="mb-4 text-sm text-brand-inkMuted">
                Còn {subscription.daysRemaining} ngày · hết hạn {formatDate(subscription.endDate)}
              </p>
            </>
          ) : (
            <>
              <p className="mb-1 text-xl font-bold text-brand-ink">Miễn phí</p>
              <p className="mb-4 text-sm text-brand-inkMuted">Nâng cấp để mở khoá AI tạo lịch tập và phân tích ảnh/video.</p>
            </>
          )}
          {!isPremium && (
            <Link to="/checkout" className="btn-primary mt-auto">
              <Sparkles className="h-4 w-4" />
              Nâng cấp Premium
            </Link>
          )}
        </div>
      </div>

      {/* Stats row */}
      <div className="mb-8 grid grid-cols-2 gap-4 sm:grid-cols-4">
        <StatCard icon={Flame} color="bg-sticker-orange" value={home?.streak ?? 0} label="Ngày streak" />
        <StatCard icon={Dumbbell} color="bg-sticker-teal" value={home?.workoutCount ?? 0} label="Buổi đã hoàn thành" />
        <StatCard
          icon={CalendarDays}
          color="bg-sticker-sky"
          value={home?.popularExercises?.length ?? 0}
          label="Bài tập tuần này"
        />
        <StatCard icon={Award} color="bg-sticker-purple" value={home?.badges?.length ?? 0} label="Huy hiệu đạt được" />
      </div>

      <div className="mb-8 grid gap-6 lg:grid-cols-3">
        {/* Muscle progress */}
        <div className="feature-card lg:col-span-2">
          <h2 className="mb-4 text-lg font-semibold text-brand-ink">Tiến độ nhóm cơ</h2>
          {topMuscles.length === 0 ? (
            <p className="text-sm text-brand-inkMuted">Bắt đầu tập luyện để xem tiến độ từng nhóm cơ.</p>
          ) : (
            <div className="space-y-4">
              {topMuscles.map((m) => {
                const tier = getTierMeta(m.tier)
                return (
                  <div key={m.muscleId}>
                    <div className="mb-1 flex items-center justify-between text-sm">
                      <span className="font-medium text-brand-ink">{m.name}</span>
                      <span className="text-brand-inkMuted">
                        Cấp {m.level} · <span style={{ color: tier.color }}>{tier.label}</span>
                      </span>
                    </div>
                    <div className="h-2 w-full overflow-hidden rounded-full bg-brand-canvasSoft">
                      <div
                        className="h-full rounded-full"
                        style={{ width: `${Math.round((m.progress ?? 0) * 100)}%`, backgroundColor: tier.color }}
                      />
                    </div>
                  </div>
                )
              })}
            </div>
          )}
        </div>

        {/* Today's plan */}
        <div className="feature-card">
          <h2 className="mb-4 text-lg font-semibold text-brand-ink">Buổi tập hôm nay</h2>
          {home?.todayPlan ? (
            <>
              <p className="mb-1 text-sm font-medium text-brand-primary">{home.todayPlan.day}</p>
              <p className="mb-3 text-sm text-brand-inkMuted">{home.todayPlan.focus}</p>
              <ul className="space-y-2">
                {home.todayPlan.exercises.map((ex) => (
                  <li key={ex.id} className="flex items-center justify-between text-sm">
                    <span className="text-brand-ink">{ex.name}</span>
                    <span className="text-brand-inkMuted">
                      {ex.sets}x{ex.reps}
                    </span>
                  </li>
                ))}
              </ul>
            </>
          ) : (
            <p className="text-sm text-brand-inkMuted">Không có buổi tập nào được lên lịch cho hôm nay.</p>
          )}
        </div>
      </div>

      {/* Recent history */}
      <div className="feature-card">
        <h2 className="mb-4 text-lg font-semibold text-brand-ink">Lịch sử tập luyện gần đây</h2>
        {recentHistory.length === 0 ? (
          <p className="text-sm text-brand-inkMuted">Chưa có buổi tập nào được ghi lại.</p>
        ) : (
          <div className="space-y-3">
            {recentHistory.map((session) => {
              const status = statusMeta(session.status)
              return (
                <div
                  key={session.id}
                  className="flex flex-wrap items-center justify-between gap-2 border-b border-brand-hairline pb-3 last:border-none last:pb-0"
                >
                  <div>
                    <p className="text-sm font-medium text-brand-ink">{session.name || session.focus || 'Buổi tập'}</p>
                    <p className="text-xs text-brand-inkMuted">{formatDate(session.startTime)}</p>
                  </div>
                  <div className="flex items-center gap-3 text-xs">
                    <span className="text-brand-inkMuted">{formatDuration(session.totalDurationSeconds)}</span>
                    <span className={`rounded-full px-2.5 py-1 font-semibold ${status.className}`}>{status.label}</span>
                  </div>
                </div>
              )
            })}
          </div>
        )}
      </div>
    </div>
  )
}

function Stat({ label, value }) {
  return (
    <div>
      <p className="text-xs text-brand-inkFaint">{label}</p>
      <p className="text-sm font-semibold text-brand-ink">{value}</p>
    </div>
  )
}

function StatCard({ icon: Icon, color, value, label }) {
  return (
    <div className="feature-card flex flex-col items-start gap-3">
      <span className={`flex h-10 w-10 items-center justify-center rounded-md ${color}`}>
        <Icon className="h-5 w-5 text-white" />
      </span>
      <div>
        <p className="text-2xl font-bold text-brand-ink">{value}</p>
        <p className="text-xs text-brand-inkMuted">{label}</p>
      </div>
    </div>
  )
}
