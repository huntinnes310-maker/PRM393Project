import apiClient from './apiClient.js'

export async function getMySubscription() {
  const { data } = await apiClient.get('/api/subscriptions/me')
  if (data?.message) return null
  return data
}

export async function getActivePlans() {
  const { data } = await apiClient.get('/api/subscriptions/plans/active')
  return data
}
