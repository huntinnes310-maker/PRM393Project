import apiClient from './apiClient.js'

export async function login(email, password) {
  const { data } = await apiClient.post('/api/Auth/login', { email, password })
  localStorage.setItem('token', data.token)
  localStorage.setItem('user', JSON.stringify({ userId: data.userId, role: data.role, email }))
  return data
}

export async function registerCustomer(fullName, email, password) {
  const { data } = await apiClient.post('/api/Auth/register/customer', { fullName, email, password })
  return data
}

export function logout() {
  localStorage.removeItem('token')
  localStorage.removeItem('user')
}

export function getCurrentUser() {
  const raw = localStorage.getItem('user')
  if (!raw) return null
  try {
    return JSON.parse(raw)
  } catch {
    return null
  }
}

export function isAuthenticated() {
  return Boolean(localStorage.getItem('token'))
}
