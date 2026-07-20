import { useEffect, useRef, useState } from 'react'
import { QRCodeSVG } from 'qrcode.react'
import { CheckCircle2, ExternalLink } from 'lucide-react'
import { getActivePlans } from '../services/subscriptionService.js'
import { createCheckout, getStatus } from '../services/paymentService.js'
import { useAuth } from '../context/AuthContext.jsx'

const TERMINAL_STATUSES = new Set(['Paid', 'Cancelled', 'Failed', 'Refunded'])

function formatVnd(amount) {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount)
}

export default function Checkout() {
  const { refreshSubscription } = useAuth()
  const [plans, setPlans] = useState([])
  const [selectedPlanId, setSelectedPlanId] = useState('')
  const [checkout, setCheckout] = useState(null)
  const [status, setStatus] = useState(null)
  const [error, setError] = useState('')
  const [creating, setCreating] = useState(false)
  const pollRef = useRef(null)

  useEffect(() => {
    getActivePlans().then((data) => {
      setPlans(data)
      if (data.length > 0) setSelectedPlanId(data[0].id)
    }).catch(() => setPlans([]))
  }, [])

  useEffect(() => {
    return () => clearInterval(pollRef.current)
  }, [])

  const selectedPlan = plans.find((p) => p.id === selectedPlanId)

  async function handlePay() {
    if (!selectedPlanId) return
    setError('')
    setCreating(true)
    try {
      const result = await createCheckout(selectedPlanId)
      setCheckout(result)
      setStatus(result.status)
      startPolling(result.orderCode)
    } catch (err) {
      setError(err.response?.data?.message || 'Không tạo được đơn thanh toán. Vui lòng thử lại.')
    } finally {
      setCreating(false)
    }
  }

  function startPolling(orderCode) {
    clearInterval(pollRef.current)
    pollRef.current = setInterval(async () => {
      try {
        const result = await getStatus(orderCode)
        setStatus(result.status)
        if (TERMINAL_STATUSES.has(result.status)) {
          clearInterval(pollRef.current)
          if (result.status === 'Paid') await refreshSubscription()
        }
      } catch {
        // bỏ qua lỗi tạm thời, vòng poll tiếp theo sẽ thử lại
      }
    }, 3000)
  }

  if (status === 'Paid') {
    return (
      <div className="mx-auto flex min-h-[70vh] max-w-md flex-col items-center justify-center px-6 text-center">
        <CheckCircle2 className="mb-4 h-16 w-16 text-brand-success" />
        <h1 className="mb-2 text-2xl font-bold text-brand-ink">Thanh toán thành công!</h1>
        <p className="text-brand-inkMuted">Tài khoản của bạn đã được nâng cấp lên Premium.</p>
      </div>
    )
  }

  return (
    <div className="mx-auto max-w-md px-6 py-12">
      <h1 className="mb-6 text-2xl font-bold text-brand-ink">Nâng cấp Premium</h1>

      {!checkout ? (
        <div className="feature-card space-y-4">
          <div>
            <label className="mb-1 block text-sm font-medium text-brand-inkSecondary">Chọn gói</label>
            <select
              value={selectedPlanId}
              onChange={(e) => setSelectedPlanId(e.target.value)}
              className="text-input"
            >
              {plans.map((plan) => (
                <option key={plan.id} value={plan.id}>{plan.name}</option>
              ))}
            </select>
          </div>

          {selectedPlan && (
            <div className="rounded-md border border-brand-hairline bg-brand-canvasSoft p-4">
              <p className="text-2xl font-bold text-brand-primary">{formatVnd(selectedPlan.price)}</p>
              <p className="text-sm text-brand-inkMuted">{selectedPlan.durationMonths} tháng</p>
            </div>
          )}

          {error && <p className="text-sm text-brand-danger">{error}</p>}

          <button onClick={handlePay} disabled={creating || !selectedPlanId} className="btn-primary w-full">
            {creating ? 'Đang tạo đơn thanh toán...' : 'Thanh toán'}
          </button>
        </div>
      ) : (
        <div className="feature-card flex flex-col items-center text-center">
          <p className="mb-4 text-sm text-brand-inkMuted">
            Quét mã QR bằng ứng dụng ngân hàng để thanh toán {formatVnd(checkout.amount)}
          </p>
          <div className="mb-4 rounded-xl border border-brand-hairline bg-white p-4">
            <QRCodeSVG value={checkout.qrCode} size={220} />
          </div>
          <p className="mb-4 flex items-center gap-2 text-sm text-brand-inkMuted">
            <span className="h-2 w-2 animate-pulse rounded-full bg-brand-warning" />
            Đang chờ thanh toán...
          </p>
          <a
            href={checkout.checkoutUrl}
            target="_blank"
            rel="noreferrer"
            className="btn-utility flex items-center gap-2"
          >
            Mở trang thanh toán
            <ExternalLink className="h-4 w-4" />
          </a>
        </div>
      )}
    </div>
  )
}
