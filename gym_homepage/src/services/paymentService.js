import apiClient from './apiClient.js'

export async function createCheckout(planId) {
  const { data } = await apiClient.post('/api/payments/payos/checkout', { planId })
  return data
}

export async function getStatus(orderCode) {
  const { data } = await apiClient.get(`/api/payments/payos/status/${orderCode}`)
  return data
}
