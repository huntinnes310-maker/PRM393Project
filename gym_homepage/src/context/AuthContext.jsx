import { createContext, useContext, useEffect, useState, useCallback } from 'react'
import * as authService from '../services/authService.js'
import { getUserById } from '../services/userService.js'
import { getMySubscription } from '../services/subscriptionService.js'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [user, setUser] = useState(authService.getCurrentUser())
  const [subscription, setSubscription] = useState(null)
  const [loading, setLoading] = useState(authService.isAuthenticated())

  const refreshSubscription = useCallback(async () => {
    if (!authService.isAuthenticated()) return
    try {
      const sub = await getMySubscription()
      setSubscription(sub)
    } catch {
      setSubscription(null)
    }
  }, [])

  useEffect(() => {
    if (!authService.isAuthenticated()) {
      setLoading(false)
      return
    }
    const stored = authService.getCurrentUser()
    if (!stored?.userId) {
      setLoading(false)
      return
    }

    let cancelled = false
    ;(async () => {
      try {
        const [profile, sub] = await Promise.all([
          getUserById(stored.userId),
          getMySubscription(),
        ])
        if (cancelled) return
        setUser({ ...stored, fullName: profile?.fullName })
        setSubscription(sub)
      } catch {
        // token có thể hết hạn/không hợp lệ — không chặn UI, chỉ giữ dữ liệu đã cache
      } finally {
        if (!cancelled) setLoading(false)
      }
    })()

    return () => {
      cancelled = true
    }
  }, [])

  async function login(email, password) {
    const data = await authService.login(email, password)
    const profile = await getUserById(data.userId).catch(() => null)
    setUser({ userId: data.userId, role: data.role, email, fullName: profile?.fullName })
    await refreshSubscription()
    return data
  }

  async function registerCustomer(fullName, email, password) {
    return authService.registerCustomer(fullName, email, password)
  }

  function logout() {
    authService.logout()
    setUser(null)
    setSubscription(null)
  }

  const isPremium = Boolean(subscription?.isPremium)

  return (
    <AuthContext.Provider
      value={{ user, subscription, isPremium, loading, login, registerCustomer, logout, refreshSubscription }}
    >
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
